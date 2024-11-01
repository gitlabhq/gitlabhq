# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Updates issue_search_data.namespace_id with the associated issue's namespace_id
    class BackfillIssueSearchDataNamespaceId < BatchedMigrationJob
      feature_category :team_planning
      operation_name :backfill_issue_search_data_namespace_id

      # migrations only version of `issue_search_data` table
      class IssueSearchData < ::ApplicationRecord
        self.table_name = 'issue_search_data'
      end

      def perform
        each_sub_batch do |sub_batch|
          issues_by_project = sub_batch
            .where.not(project_id: nil)
            .pluck(:project_id, :namespace_id, :id)
            .group_by(&:first)

          issues_by_project.each do |project_id, issues|
            namespace_id = issues.first[1]
            issue_ids = issues.pluck(2)

            IssueSearchData
              .where(issue_id: issue_ids, project_id: project_id)
              .update_all(namespace_id: namespace_id)
          end
        end
      end
    end
  end
end
