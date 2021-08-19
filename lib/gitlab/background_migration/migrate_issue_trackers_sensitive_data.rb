# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This migration takes all issue trackers
    # and move data from properties to data field tables (jira_tracker_data and issue_tracker_data)
    class MigrateIssueTrackersSensitiveData
      delegate :select_all, :execute, :quote_string, to: :connection

      # we need to define this class and set fields encryption
      class IssueTrackerData < ApplicationRecord
        self.table_name = 'issue_tracker_data'

        def self.encryption_options
          {
            key: Settings.attr_encrypted_db_key_base_32,
            encode: true,
            mode: :per_attribute_iv,
            algorithm: 'aes-256-gcm'
          }
        end

        attr_encrypted :project_url, encryption_options
        attr_encrypted :issues_url, encryption_options
        attr_encrypted :new_issue_url, encryption_options
      end

      # we need to define this class and set fields encryption
      class JiraTrackerData < ApplicationRecord
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
        attr_encrypted :username, encryption_options
        attr_encrypted :password, encryption_options
      end

      def perform(start_id, stop_id)
        columns = 'id, properties, title, description, type'
        batch_condition = "id >= #{start_id} AND id <= #{stop_id} AND category = 'issue_tracker' \
          AND properties IS NOT NULL AND properties != '{}' AND properties != ''"

        data_subselect = "SELECT 1 \
          FROM jira_tracker_data \
          WHERE jira_tracker_data.service_id = services.id \
          UNION SELECT 1 \
          FROM issue_tracker_data \
          WHERE issue_tracker_data.service_id = services.id"

        query = "SELECT #{columns} FROM services WHERE #{batch_condition} AND NOT EXISTS (#{data_subselect})"

        migrated_ids = []
        data_to_insert(query).each do |table, data|
          service_ids = data.map { |s| s['service_id'] }

          next if service_ids.empty?

          migrated_ids += service_ids
          Gitlab::Database.main.bulk_insert(table, data) # rubocop:disable Gitlab/BulkInsert
        end

        return if migrated_ids.empty?

        move_title_description(migrated_ids)
      end

      private

      def data_to_insert(query)
        data = { 'jira_tracker_data' => [], 'issue_tracker_data' => [] }
        select_all(query).each do |service|
          begin
            properties = Gitlab::Json.parse(service['properties'])
          rescue JSON::ParserError
            logger.warn(
              message: 'Properties data not parsed - invalid json',
              service_id: service['id'],
              properties: service['properties']
            )
            next
          end

          if service['type'] == 'JiraService'
            row = data_row(JiraTrackerData, jira_mapping(properties), service)
            key = 'jira_tracker_data'
          else
            row = data_row(IssueTrackerData, issue_tracker_mapping(properties), service)
            key = 'issue_tracker_data'
          end

          data[key] << row if row
        end

        data
      end

      def data_row(klass, mapping, service)
        base_params = { service_id: service['id'], created_at: Time.current, updated_at: Time.current }
        klass.new(mapping).slice(*klass.column_names).compact.merge(base_params)
      end

      def move_title_description(service_ids)
        query = "UPDATE services SET \
          title = cast(properties as json)->>'title', \
          description = cast(properties as json)->>'description' \
          WHERE id IN (#{service_ids.join(',')}) AND title IS NULL AND description IS NULL"

        execute(query)
      end

      def jira_mapping(properties)
        {
          url: properties['url'],
          api_url: properties['api_url'],
          username: properties['username'],
          password: properties['password']
        }
      end

      def issue_tracker_mapping(properties)
        {
          project_url: properties['project_url'],
          issues_url: properties['issues_url'],
          new_issue_url: properties['new_issue_url']
        }
      end

      def connection
        @connection ||= ActiveRecord::Base.connection
      end

      def logger
        @logger ||= Gitlab::BackgroundMigration::Logger.build
      end
    end
  end
end
