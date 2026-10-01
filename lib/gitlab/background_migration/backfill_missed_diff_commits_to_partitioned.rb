# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Copies diff commit rows that BackfillMergeRequestDiffCommitsToPartitioned's filtered_diff_commits_cte
    # skipped (NULL sha, commit_author_id, or committer_id) - the shape of every row written once
    # merge_request_diff_commits_dedup moved commit data to merge_request_commits_metadata and left only
    # a pointer. That pointer is still there, so nothing needs inserting into the metadata table.
    #
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/628194
    #
    # rubocop: disable Migration/BatchedMigrationBaseClass -- indirectly derives from the correct base class
    class BackfillMissedDiffCommitsToPartitioned < BackfillPartitionedTable
      operation_name :backfill_missed_diff_commits
      feature_category :code_review_workflow

      # Names the write target, not the iteration table.
      tables_to_check_for_vacuum :merge_request_diff_commits

      cursor :merge_request_diff_id, :relative_order

      COPIED_COLUMNS = %i[merge_request_diff_id relative_order merge_request_commits_metadata_id].freeze

      def perform
        validate_partition_table!

        each_sub_batch do |sub_batch|
          connection.execute(copy_sub_batch(sub_batch))
        end
      end

      private

      def copy_sub_batch(relation)
        <<~SQL
          #{sub_batch_cte(relation)}
          #{missing_commits_cte}
          #{insert_into_partitioned_table}
        SQL
      end

      # Selects only the copied columns, not the whole row, to keep message and trailers out of the
      # materialized CTE.
      def sub_batch_cte(relation)
        <<~SQL
          WITH sub_batch AS MATERIALIZED (
            #{relation.select(*COPIED_COLUMNS).limit(sub_batch_size).to_sql}
          ),
        SQL
      end

      # archived.project_id is NULL here: it was never backfilled and only started being written after
      # merge_request_diff_commits_partition was enabled, so project_id comes from merge_request_diffs.
      # The INNER JOIN also drops commits with a deleted parent diff, as the original backfill did.
      def missing_commits_cte
        <<~SQL
          missing_commits AS MATERIALIZED (
            SELECT
              archived.merge_request_diff_id,
              archived.relative_order,
              archived.merge_request_commits_metadata_id,
              mr_diffs.project_id
            FROM sub_batch AS archived
            INNER JOIN merge_request_diffs AS mr_diffs
              ON mr_diffs.id = archived.merge_request_diff_id
            WHERE archived.merge_request_commits_metadata_id IS NOT NULL
            LIMIT #{sub_batch_size}
          )
        SQL
      end

      # The legacy columns added by AddLegacyColumnsToPartitionedMergeRequestDiffCommits stay NULL:
      # nothing reads or writes them.
      def insert_into_partitioned_table
        <<~SQL
          INSERT INTO #{partitioned_table} (
            merge_request_commits_metadata_id,
            merge_request_diff_id,
            project_id,
            relative_order
          )
          SELECT
            merge_request_commits_metadata_id,
            merge_request_diff_id,
            project_id,
            relative_order
          FROM missing_commits
          ON CONFLICT (merge_request_diff_id, relative_order, project_id) DO NOTHING
        SQL
      end
    end
    # rubocop: enable Migration/BatchedMigrationBaseClass
  end
end
