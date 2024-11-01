# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class that fixes the incorrectly set authored_date within
    # issue_metrics table
    class FixFirstMentionedInCommitAt
      SUB_BATCH_SIZE = 500

      class TmpIssueMetrics < ActiveRecord::Base
        include EachBatch

        self.table_name = 'issue_metrics'

        def self.from_2020
          where(first_mentioned_in_commit_at_condition)
        end

        def self.first_mentioned_in_commit_at_condition
          if columns_hash['first_mentioned_in_commit_at'].sql_type == 'timestamp without time zone'
            'EXTRACT(YEAR FROM first_mentioned_in_commit_at) > 2019'
          else
            "EXTRACT(YEAR FROM first_mentioned_in_commit_at at time zone 'UTC') > 2019"
          end
        end
      end

      def perform(start_id, end_id)
        scope(start_id, end_id).each_batch(of: SUB_BATCH_SIZE, column: :issue_id) do |sub_batch|
          first, last = sub_batch.pick(Arel.sql('min(issue_id), max(issue_id)'))

          # The query need to be reconstructed because .each_batch modifies the default scope
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/330510
          inner_query = TmpIssueMetrics
            .unscoped
            .merge(scope(first, last))
            .from("issue_metrics, #{lateral_query}")
            .select('issue_metrics.issue_id', 'first_authored_date.authored_date')
            .where('issue_metrics.first_mentioned_in_commit_at > first_authored_date.authored_date')

          TmpIssueMetrics.connection.execute <<~UPDATE_METRICS
            WITH cte AS MATERIALIZED (
              #{inner_query.to_sql}
            )
            UPDATE issue_metrics
            SET
              first_mentioned_in_commit_at = cte.authored_date
            FROM
              cte
            WHERE
              cte.issue_id = issue_metrics.issue_id
          UPDATE_METRICS
        end

        mark_job_as_succeeded(start_id, end_id)
      end

      private

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          'FixFirstMentionedInCommitAt',
          arguments
        )
      end

      def scope(start_id, end_id)
        TmpIssueMetrics.from_2020.where(issue_id: start_id..end_id)
      end

      def lateral_query
        <<~SQL
        LATERAL (
          SELECT MIN(first_authored_date.authored_date) as authored_date
          FROM merge_requests_closing_issues,
          LATERAL (
            SELECT id
            FROM merge_request_diffs
            WHERE merge_request_id = merge_requests_closing_issues.merge_request_id
            ORDER BY id DESC
            LIMIT 1
          ) last_diff_id,
          LATERAL (
            SELECT authored_date
            FROM merge_request_diff_commits
            WHERE
            merge_request_diff_id = last_diff_id.id
            ORDER BY relative_order DESC
            LIMIT 1
          ) first_authored_date
          WHERE merge_requests_closing_issues.issue_id = issue_metrics.issue_id
        ) first_authored_date
        SQL
      end
    end
  end
end
