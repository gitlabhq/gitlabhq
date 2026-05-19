# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BatchedMigrationBaseClass -- This is indirectly deriving from the correct base class
    # rubocop:disable Metrics/ClassLength -- Necessary for migration
    class BackfillMergeRequestDiffCommitsToPartitioned < BackfillPartitionedTable
      operation_name :backfill_partitioned_table
      feature_category :code_review_workflow

      tables_to_check_for_vacuum :merge_request_diff_commits_b5377a7a34, :merge_request_commits_metadata

      cursor :merge_request_diff_id, :relative_order

      def perform
        validate_partition_table!

        each_sub_batch do |relation|
          backfill_batch(relation)
        end
      end

      private

      # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- override only applies to migration ran for .com_except_jh?
      def sub_batch_relation(**)
        return super unless Gitlab.com_except_jh?

        base_class = Gitlab::Database.application_record_for_connection(connection)
        # Use the underlying table directly rather than batch_table (the view on .com) to avoid
        # PostgreSQL failing to collapse row-style index conditions through views.
        # The cursor bounds are replicated from base_relation against the underlying table so the scope stays consistent
        model_class = define_batchable_model('merge_request_diff_commits', connection: connection,
          base_class: base_class)

        cursor_expression = Arel::Nodes::Grouping.new(
          cursor_columns.map { |col| model_class.arel_table[col] }
        )
        underlying_relation = model_class.where(
          Arel::Nodes::And.new([
            cursor_expression.gteq(arel_for_cursor(start_cursor, model_class.arel_table)),
            cursor_expression.lteq(arel_for_cursor(end_cursor, model_class.arel_table))
          ])
        )

        Gitlab::Pagination::Keyset::Iterator.new(scope: underlying_relation.order(cursor_columns))
      end
      # rubocop:enable Gitlab/AvoidGitlabInstanceChecks

      def backfill_batch(relation)
        connection.execute(<<~SQL)
          #{sub_batch_cte(relation)}
          #{diff_commits_cte}
          #{filtered_diff_commits_cte}
          #{metadata_keys_cte}
          #{inserted_metadata_cte}
          #{insert_into_partitioned_table}
        SQL
      end

      # Wraps the sub-batch relation with an explicit LIMIT so the planner knows the upper bound.
      def sub_batch_cte(relation)
        <<~SQL
          WITH sub_batch AS MATERIALIZED (
            #{relation.limit(sub_batch_size).to_sql}
          ),
        SQL
      end

      # Joins to merge_request_diff_commits to get full row data (sub_batch may only contain cursor
      # columns when iterating via a view), then joins merge_request_diffs to get project_id and
      # merge_request_id. The INNER JOINs intentionally drop commits whose parent rows no longer
      # exist - these are orphaned rows mid-deletion and do not need to be present in the
      # partitioned table.
      def diff_commits_cte
        <<~SQL
          diff_commits AS MATERIALIZED (
            SELECT
              mrdc.merge_request_diff_id,
              mrdc.relative_order,
              mrdc.sha,
              mrdc.commit_author_id,
              mrdc.committer_id,
              mrdc.authored_date,
              mrdc.committed_date,
              mrdc.message,
              mrdc.merge_request_commits_metadata_id,
              mr_diffs.merge_request_id,
              mr_diffs.project_id
            FROM sub_batch
            INNER JOIN merge_request_diff_commits AS mrdc
              ON mrdc.merge_request_diff_id = sub_batch.merge_request_diff_id
              AND mrdc.relative_order = sub_batch.relative_order
            INNER JOIN merge_request_diffs AS mr_diffs
              ON mr_diffs.id = sub_batch.merge_request_diff_id
            LIMIT #{sub_batch_size}
          ),
        SQL
      end

      # Excludes commits from merge requests in the excluded_merge_requests table.
      # Also excludes rows where columns required by merge_request_commits_metadata are NULL
      # in the source table - these are legacy rows that cannot be migrated.
      def filtered_diff_commits_cte
        <<~SQL
          filtered_diff_commits AS MATERIALIZED (
            SELECT diff_commits.*
            FROM diff_commits
            WHERE NOT EXISTS (
              SELECT 1
              FROM excluded_merge_requests AS excluded_mrs
              WHERE excluded_mrs.merge_request_id = diff_commits.merge_request_id
            )
            AND diff_commits.commit_author_id IS NOT NULL
            AND diff_commits.committer_id IS NOT NULL
            AND diff_commits.sha IS NOT NULL
            LIMIT #{sub_batch_size}
          ),
        SQL
      end

      # Identifies unique (project_id, sha) pairs that need metadata records created.
      # Filters to rows missing merge_request_commits_metadata_id.
      # Duplicate (project_id, sha) rows originate from the same commit being copied across diffs,
      # so all columns are identical and picking any row is safe.
      def metadata_keys_cte
        <<~SQL
          metadata_keys AS MATERIALIZED (
            SELECT DISTINCT ON (project_id, sha)
              project_id,
              sha,
              commit_author_id,
              committer_id,
              authored_date,
              committed_date,
              message
            FROM filtered_diff_commits
            WHERE merge_request_commits_metadata_id IS NULL
            ORDER BY project_id, sha
            LIMIT #{sub_batch_size}
          ),
        SQL
      end

      # Inserts metadata records for unique (project_id, sha) pairs.
      # DO UPDATE SET sha = EXCLUDED.sha is a no-op that forces RETURNING to include
      # both newly inserted and pre-existing conflicting rows, avoiding a separate lookup CTE.
      def inserted_metadata_cte
        <<~SQL
          inserted_metadata AS (
            INSERT INTO merge_request_commits_metadata (
              project_id,
              sha,
              commit_author_id,
              committer_id,
              authored_date,
              committed_date,
              message
            )
            SELECT
              project_id,
              sha,
              commit_author_id,
              committer_id,
              authored_date,
              committed_date,
              message
            FROM metadata_keys
            ON CONFLICT (project_id, sha) DO UPDATE SET sha = EXCLUDED.sha
            RETURNING id, project_id, sha
          )
        SQL
      end

      # Inserts commit records into the partitioned table.
      # COALESCE picks the existing metadata_id from filtered_diff_commits if already backfilled,
      # or falls back to the id returned from inserted_metadata.
      def insert_into_partitioned_table
        <<~SQL
          INSERT INTO #{partitioned_table} (
            merge_request_commits_metadata_id,
            merge_request_diff_id,
            project_id,
            relative_order
          )
          SELECT
            COALESCE(dc.merge_request_commits_metadata_id, im.id),
            dc.merge_request_diff_id,
            dc.project_id,
            dc.relative_order
          FROM filtered_diff_commits AS dc
          LEFT JOIN inserted_metadata AS im
            ON im.project_id = dc.project_id
            AND im.sha = dc.sha
          ON CONFLICT (merge_request_diff_id, relative_order, project_id) DO NOTHING
        SQL
      end
    end
    # rubocop:enable Migration/BatchedMigrationBaseClass
    # rubocop:enable Metrics/ClassLength
  end
end
