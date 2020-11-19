# frozen_string_literal: true

# Based on https://community.developer.atlassian.com/t/get-rest-api-3-filter-search/29459/2,
# it's enough at the moment to simply notice if the url is from `atlassian.net`
module Gitlab
  module BackgroundMigration
    # Backfill the deployment_type in jira_tracker_data table
    class BackfillJiraTrackerDeploymentType2
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

      def perform(start_id, stop_id)
        @server_ids = []
        @cloud_ids  = []

        JiraTrackerDataTemp
          .where(id: start_id..stop_id, deployment_type: 0)
          .each do |jira_tracker_data|
            collect_deployment_type(jira_tracker_data)
          end

        unless cloud_ids.empty?
          JiraTrackerDataTemp.where(id: cloud_ids)
            .update_all(deployment_type: JiraTrackerDataTemp.deployment_types[:cloud])
        end

        unless server_ids.empty?
          JiraTrackerDataTemp.where(id: server_ids)
            .update_all(deployment_type: JiraTrackerDataTemp.deployment_types[:server])
        end

        mark_jobs_as_succeeded(start_id, stop_id)
      end

      private

      attr_reader :server_ids, :cloud_ids

      def client_url(jira_tracker_data)
        jira_tracker_data.api_url.presence || jira_tracker_data.url.presence
      end

      def server_type(url)
        url.downcase.include?('.atlassian.net') ? :cloud : :server
      end

      def collect_deployment_type(jira_tracker_data)
        url = client_url(jira_tracker_data)
        return unless url

        case server_type(url)
        when :cloud
          cloud_ids << jira_tracker_data.id
        else
          server_ids << jira_tracker_data.id
        end
      end

      def mark_jobs_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(self.class.name, arguments)
      end
    end
  end
end
