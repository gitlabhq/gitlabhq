# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class UpdateJiraTrackerDataDeploymentTypeBasedOnUrl < Gitlab::BackgroundMigration::BatchedMigrationJob
      feature_category :database

      class JiraTrackerData < ActiveRecord::Base
        self.table_name = "jira_tracker_data"
        self.inheritance_column = :_type_disabled

        include ::Integrations::BaseDataFields
        attr_encrypted :url, encryption_options
        attr_encrypted :api_url, encryption_options

        enum deployment_type: { unknown: 0, server: 1, cloud: 2 }, _prefix: :deployment
      end
      # https://rubular.com/r/uwgK7k9KH23efa
      JIRA_CLOUD_REGEX = %r{^https?://[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?\.atlassian\.net$}ix

      def perform
        cloud = []
        server = []
        unknown = []

        trackers_data.each do |tracker_data|
          client_url = tracker_data.api_url.presence || tracker_data.url

          if client_url.blank?
            unknown << tracker_data
          elsif client_url.match?(JIRA_CLOUD_REGEX)
            cloud << tracker_data
          else
            server << tracker_data
          end
        end

        cloud_mappings = cloud.index_with do
          { deployment_type: 2 }
        end

        server_mappings = server.index_with do
          { deployment_type: 1 }
        end

        unknown_mappings = unknown.index_with do
          { deployment_type: 0 }
        end

        mappings = cloud_mappings.merge(server_mappings, unknown_mappings)

        update_records(mappings)
      end

      private

      def update_records(mappings)
        return if mappings.empty?

        ::Gitlab::Database::BulkUpdate.execute(%i[deployment_type], mappings)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def trackers_data
        @trackers_data ||= JiraTrackerData
          .where(deployment_type: 'unknown')
          .where(batch_column => start_id..end_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
