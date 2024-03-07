# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillHasIssuesForExternalIssueLinks < BatchedMigrationJob
      operation_name :backfill_has_issues_for_external_issue_links
      scope_to ->(relation) { relation.where(has_issues: false) }
      feature_category :vulnerability_management

      UPDATE_SQL = <<~SQL
        UPDATE
          vulnerability_reads
        SET
          has_issues = true
        FROM
          (%<subquery>s) as sub_query
        WHERE
          vulnerability_reads.vulnerability_id = sub_query.vulnerability_id
      SQL

      def perform
        each_sub_batch do |sub_batch|
          update_query = update_query_for(sub_batch)

          connection.execute(update_query)
        end
      end

      private

      def update_query_for(sub_batch)
        subquery = sub_batch.joins("
          INNER JOIN vulnerability_external_issue_links ON
          vulnerability_reads.vulnerability_id =
          vulnerability_external_issue_links.vulnerability_id")

        format(UPDATE_SQL, subquery: subquery.to_sql)
      end
    end
  end
end
