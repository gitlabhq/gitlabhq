# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class CreateJiraCloudAppIntegrationForJiraConnectSubscription < BatchedMigrationJob
      operation_name :create_jira_cloud_app_integration_for_jira_connect_subscriptions # for metrics
      feature_category :integrations

      class Integration < ::ApplicationRecord
        self.table_name = 'integrations'
      end

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.each do |subscription|
            integration = Integration.find_or_create_by(active: true, type_new: 'Integrations::JiraCloudApp',
              group_id: subscription.namespace_id)

            PropagateIntegrationWorker.perform_async(integration.id)
          end
        end
      end
    end
  end
end
