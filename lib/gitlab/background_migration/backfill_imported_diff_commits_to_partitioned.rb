# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Copies diff commits of projects imported through import/export in 2021 that are missing from the
    # partitioned table. Those rows were left with NULL commit_author_id or committer_id by the import
    # (https://gitlab.com/gitlab-org/gitlab/-/issues/344080), so BackfillMergeRequestDiffCommitsToPartitioned
    # excluded them. The missing users are replaced by a placeholder, to be restored from Gitaly in a follow-up.
    #
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/630899
    class BackfillImportedDiffCommitsToPartitioned < BatchedMigrationJob # rubocop:disable Metrics/ClassLength -- SQL heredocs
      operation_name :backfill_imported_diff_commits
      feature_category :code_review_workflow

      # Iterates merge_request_diffs, but only writes to these.
      tables_to_check_for_vacuum :merge_request_diff_commits, :merge_request_commits_metadata

      cursor :id

      job_arguments :source_table, :partitioned_table, :min_project_id, :max_project_id

      # Only import/export imports carried the pre-14.1 commit user format.
      IMPORT_TYPES = %w[gitlab_project gitlab_custom_project_template gitlab_built_in_project_template].freeze

      # Fixed so retries reuse the same row and the Gitaly restore can find it. The .invalid TLD (RFC 2606)
      # can never be a confirmed user email, and the hash keeps it from matching a real commit author.
      PLACEHOLDER_NAME = 'Unknown author'
      PLACEHOLDER_EMAIL = 'unknown-author-279868668f7e@noreply.gitlab.invalid'

      class DiffCommitUser < ApplicationRecord
        self.table_name = 'merge_request_diff_commit_users'

        def self.find_or_create(name, email, organization_id)
          find_or_create_by!(name: name, email: email, organization_id: organization_id)
        rescue ActiveRecord::RecordNotUnique
          retry
        end
      end

      def perform
        placeholder_id = DiffCommitUser.find_or_create(PLACEHOLDER_NAME, PLACEHOLDER_EMAIL, 1).id

        each_sub_batch do |sub_batch|
          # A sub-batch of diffs can hold more missing commits than the LIMIT in filtered_diff_commits,
          # so repeat until a run comes up short. NOT EXISTS makes each run pick up where the last one stopped.
          loop do
            inserted = connection.execute(backfill_sql(sub_batch, placeholder_id)).cmd_tuples

            break if inserted < sub_batch_size
          end
        end
      end

      private

      def backfill_sql(relation, placeholder_id)
        <<~SQL
          #{imported_diffs_cte(relation)}
          #{filtered_diff_commits_cte}
          #{metadata_keys_cte(placeholder_id)}
          #{inserted_metadata_cte}
          #{insert_into_partitioned_table}
        SQL
      end

      # merge_request_diffs.created_at is copied from the export, so the window is applied through the
      # project, whose created_at is set when the import starts.
      # No excluded_merge_requests filter: on GitLab.com, none of the excluded MRs in the target projects
      # has a diff in the [MIN_DIFF_ID, MAX_DIFF_ID] cursor range, so their commits (over 1M for some) are never read.
      def imported_diffs_cte(relation)
        <<~SQL
          WITH sub_batch AS MATERIALIZED (
            #{relation.select(:id, :project_id).limit(sub_batch_size).to_sql}
          ),
          imported_diffs AS MATERIALIZED (
            SELECT sub_batch.id, sub_batch.project_id
            FROM sub_batch
            INNER JOIN projects ON projects.id = sub_batch.project_id
            WHERE projects.id BETWEEN #{Integer(min_project_id)} AND #{Integer(max_project_id)}
              AND projects.import_type IN (#{IMPORT_TYPES.map { |type| connection.quote(type) }.join(', ')})
          ),
        SQL
      end

      # Skips rows the original backfill already copied. The constant project_id range prunes to the window's
      # partitions; the join condition alone probes all of them. LIMIT bounds each statement, since a diff can
      # have a huge commit count, and #perform repeats it until the sub-batch is done.
      def filtered_diff_commits_cte
        <<~SQL
          filtered_diff_commits AS MATERIALIZED (
            SELECT
              mrdc.merge_request_diff_id,
              mrdc.relative_order,
              mrdc.sha,
              mrdc.commit_author_id,
              mrdc.committer_id,
              mrdc.authored_date,
              mrdc.committed_date,
              mrdc.message,
              imported_diffs.project_id
            FROM imported_diffs
            INNER JOIN #{quoted_source_table} AS mrdc
              ON mrdc.merge_request_diff_id = imported_diffs.id
            WHERE mrdc.sha IS NOT NULL
              AND NOT EXISTS (
                SELECT 1
                FROM #{quoted_partitioned_table} AS partitioned
                WHERE partitioned.project_id = imported_diffs.project_id
                  AND partitioned.merge_request_diff_id = mrdc.merge_request_diff_id
                  AND partitioned.relative_order = mrdc.relative_order
                  AND partitioned.project_id BETWEEN #{Integer(min_project_id)} AND #{Integer(max_project_id)}
              )
            LIMIT #{sub_batch_size}
          ),
        SQL
      end

      # One row per (project_id, sha), as ON CONFLICT DO UPDATE can't touch a row twice in one statement. Rows of
      # the same commit can differ (older MR versions stored the message without its trailing newline), so prefer
      # real users, then the longest message; diff ID and order keep the pick the same across retries.
      def metadata_keys_cte(placeholder_id)
        <<~SQL
          metadata_keys AS MATERIALIZED (
            SELECT DISTINCT ON (filtered_diff_commits.project_id, filtered_diff_commits.sha)
              filtered_diff_commits.project_id,
              filtered_diff_commits.sha,
              COALESCE(filtered_diff_commits.commit_author_id, #{placeholder_id}) AS commit_author_id,
              COALESCE(filtered_diff_commits.committer_id, #{placeholder_id}) AS committer_id,
              filtered_diff_commits.authored_date,
              filtered_diff_commits.committed_date,
              filtered_diff_commits.message
            FROM filtered_diff_commits
            ORDER BY
              filtered_diff_commits.project_id,
              filtered_diff_commits.sha,
              (filtered_diff_commits.commit_author_id IS NULL),
              (filtered_diff_commits.committer_id IS NULL),
              length(filtered_diff_commits.message) DESC NULLS LAST,
              filtered_diff_commits.merge_request_diff_id,
              filtered_diff_commits.relative_order
          ),
        SQL
      end

      # Identical to BackfillMergeRequestDiffCommitsToPartitioned#inserted_metadata_cte.
      # DO UPDATE SET sha = EXCLUDED.sha is a no-op that makes RETURNING include pre-existing rows.
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

      # Unlike the original, uses INNER JOIN since every row in filtered_diff_commits must have a
      # metadata record -- there is no pre-existing merge_request_commits_metadata_id to fall back to.
      def insert_into_partitioned_table
        <<~SQL
          INSERT INTO #{quoted_partitioned_table} (
            merge_request_commits_metadata_id,
            merge_request_diff_id,
            project_id,
            relative_order
          )
          SELECT
            im.id,
            dc.merge_request_diff_id,
            dc.project_id,
            dc.relative_order
          FROM filtered_diff_commits AS dc
          INNER JOIN inserted_metadata AS im
            ON im.project_id = dc.project_id
            AND im.sha = dc.sha
          ON CONFLICT (merge_request_diff_id, relative_order, project_id) DO NOTHING
        SQL
      end

      def quoted_source_table
        connection.quote_table_name(source_table)
      end

      def quoted_partitioned_table
        connection.quote_table_name(partitioned_table)
      end
    end
  end
end
