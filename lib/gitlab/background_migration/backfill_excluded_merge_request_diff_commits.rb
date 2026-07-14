# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop:disable Metrics/ClassLength -- Backfilling from multiple sources increases the length
    class BackfillExcludedMergeRequestDiffCommits < BatchedMigrationJob
      operation_name :backfill_limited_merge_request_commits
      feature_category :code_review_workflow

      tables_to_check_for_vacuum :merge_request_diff_commits_b5377a7a34, :merge_request_commits_metadata

      MAX_DIFFS_PER_MR   = 1_000
      MAX_COMMITS_PER_MR = 1_000_000
      COMMIT_BATCH_SIZE  = 5_000

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.each do |row|
            execute_for_mr(row.merge_request_id)
          end
        end
      end

      private

      # Backfills a single MR by bulk-fetching up to MAX_DIFFS_PER_MR diff IDs newest-first in one
      # query, then processing each diff's commits in fixed-size batches via keyset on
      # (merge_request_diff_id, relative_order) descending. Descending ensures that if
      # MAX_COMMITS_PER_MR is hit, the most recent commits (highest relative_order) are preserved
      # and only the oldest are dropped. Each commit batch runs its own small CTE so no single
      # statement risks the 15s timeout.
      def execute_for_mr(merge_request_id)
        diff_ids = ordered_diff_ids(merge_request_id)
        return if diff_ids.empty?

        project_id = project_id_for_mr(merge_request_id)
        return unless project_id

        commits_processed = 0

        diff_ids.each do |diff_id|
          break if commits_processed >= MAX_COMMITS_PER_MR

          commits_processed += process_diff(
            diff_id: diff_id,
            project_id: project_id,
            commits_remaining: MAX_COMMITS_PER_MR - commits_processed
          )
        end
      end

      def ordered_diff_ids(merge_request_id)
        connection.select_values(<<~SQL)
          SELECT id
          FROM merge_request_diffs
          WHERE merge_request_id = #{merge_request_id}
          ORDER BY id DESC
          LIMIT #{MAX_DIFFS_PER_MR}
        SQL
      end

      # All diffs of an MR share the same project_id; a single LIMIT 1 lookup
      # is enough rather than carrying it on every row of ordered_diff_ids.
      def project_id_for_mr(merge_request_id)
        connection.select_value(<<~SQL)
          SELECT project_id
          FROM merge_request_diffs
          WHERE merge_request_id = #{merge_request_id}
          LIMIT 1
        SQL
      end

      # rubocop:disable Metrics/MethodLength -- Necessary for complex migration
      # rubocop:disable Metrics/BlockLength -- block exceeds length due to SQL query, not Ruby code
      # Iterates a single diff's commits in fixed-size batches via keyset on relative_order DESC.
      # Descending order (newest commit first) ensures the most recent commits survive if the
      # commits_remaining budget is exhausted before the diff is fully processed.
      # DO UPDATE SET sha = EXCLUDED.sha forces RETURNING to include pre-existing rows, ensuring
      # diff_commits are written even when metadata already exists for a sha.
      # The trailing SELECT reports how many source rows were read and their min relative_order,
      # used to advance the keyset cursor and to detect when the diff is exhausted.
      def process_diff(diff_id:, project_id:, commits_remaining:)
        total_inserted = 0
        cursor_relative_order = nil # nil = no upper bound; descend from the highest relative_order
        loop do
          break if total_inserted >= commits_remaining

          batch_size = [COMMIT_BATCH_SIZE, commits_remaining - total_inserted].min
          upper_bound = cursor_relative_order ? "AND diff_commits.relative_order < #{cursor_relative_order}" : ""
          row = connection.select_one(<<~SQL)
            WITH source_commits AS (
              SELECT
                diff_commits.merge_request_diff_id,
                diff_commits.relative_order,
                diff_commits.sha,
                diff_commits.commit_author_id,
                diff_commits.committer_id,
                diff_commits.authored_date,
                diff_commits.committed_date,
                diff_commits.message,
                #{project_id} AS project_id
              FROM merge_request_diff_commits AS diff_commits
              WHERE diff_commits.merge_request_diff_id = #{diff_id}
                #{upper_bound}
              ORDER BY diff_commits.relative_order DESC
              LIMIT #{batch_size}
            ),
            metadata_keys AS (
              SELECT DISTINCT ON (sha)
                sha, commit_author_id, committer_id, authored_date, committed_date, message
              FROM source_commits
              WHERE sha IS NOT NULL
                AND commit_author_id IS NOT NULL
                AND committer_id IS NOT NULL
              ORDER BY sha
            ),
            inserted_metadata AS (
              INSERT INTO merge_request_commits_metadata
                (project_id, sha, commit_author_id, committer_id, authored_date, committed_date, message)
              SELECT
                #{project_id}, sha, commit_author_id, committer_id, authored_date, committed_date, message
              FROM metadata_keys
              ON CONFLICT (project_id, sha) DO UPDATE SET sha = EXCLUDED.sha
              RETURNING id, sha
            ),
            inserted_diff_commits AS (
              INSERT INTO merge_request_diff_commits_b5377a7a34
                (merge_request_commits_metadata_id, merge_request_diff_id, project_id, relative_order)
              SELECT
                inserted_metadata.id,
                source_commits.merge_request_diff_id,
                source_commits.project_id,
                source_commits.relative_order
              FROM source_commits
              INNER JOIN inserted_metadata ON inserted_metadata.sha = source_commits.sha
              ON CONFLICT (merge_request_diff_id, relative_order, project_id) DO NOTHING
            )
            SELECT COUNT(*) AS processed, MIN(relative_order) AS last_relative_order
            FROM source_commits;
          SQL

          processed = row['processed']
          break if processed == 0

          total_inserted += processed
          cursor_relative_order = row['last_relative_order']
          break if processed < batch_size
        end

        total_inserted
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/BlockLength
      # rubocop:enable Metrics/ClassLength
    end
  end
end
