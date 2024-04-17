# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillJiraTrackerDataProjectKeys < BatchedMigrationJob
      operation_name :backfill_jira_tracker_data_project_keys

      feature_category :integrations

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where(project_keys: []).where.not(project_key: [nil, '']).find_each do |jira_tracker_data|
            jira_tracker_data.update!(project_keys: [jira_tracker_data.project_key])
          end
        end
      end
    end
  end
end
