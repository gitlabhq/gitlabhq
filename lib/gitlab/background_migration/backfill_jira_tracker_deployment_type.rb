# frozen_string_literal: true

# Based on https://community.developer.atlassian.com/t/get-rest-api-3-filter-search/29459/2,
# it's enough at the moment to simply notice if the url is from `atlassian.net`
module Gitlab
  module BackgroundMigration
    # Backfill the deployment_type in jira_tracker_data table
    class BackfillJiraTrackerDeploymentType
      # Migration only version of jira_tracker_data table
      class JiraTrackerDataTemp < ApplicationRecord
        self.table_name = 'jira_tracker_data'

        def self.encryption_options
          {
            key: Settings.attr_encrypted_db_key_base_32,
            encode: true,
            mode: :per_attribute_iv,
            algorithm: 'aes-256-gcm'
          }
        end

        attr_encrypted :url, encryption_options
        attr_encrypted :api_url, encryption_options

        enum deployment_type: { unknown: 0, server: 1, cloud: 2 }, _prefix: :deployment
      end

      # Migration only version of services table
      class JiraServiceTemp < ApplicationRecord
        self.table_name = 'services'
        self.inheritance_column = :_type_disabled
      end

      def perform(tracker_id)
        @jira_tracker_data = JiraTrackerDataTemp.find_by(id: tracker_id, deployment_type: 0)

        return unless jira_tracker_data
        return unless client_url

        update_deployment_type
      end

      private

      attr_reader :jira_tracker_data

      def client_url
        jira_tracker_data.api_url.presence || jira_tracker_data.url.presence
      end

      def server_type
        client_url.downcase.include?('.atlassian.net') ? :cloud : :server
      end

      def update_deployment_type
        case server_type
        when :server
          jira_tracker_data.deployment_server!
        when :cloud
          jira_tracker_data.deployment_cloud!
        end
      end
    end
  end
end
