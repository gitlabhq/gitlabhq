# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Iterates through the namespaces table and attempts to set the
    # opposite of the value of the column "emails_disabled" to a new
    # column in namespace_settings called emails_enabled
    class AddNamespacesEmailsEnabledColumnData < BatchedMigrationJob
      feature_category :database
      operation_name :add_namespaces_emails_enabled_column_data

      # Targeted table
      class NamespaceSetting < ApplicationRecord
        self.table_name = 'namespace_settings'
      end

      def perform
        each_sub_batch do |sub_batch|
          plucked_list = sub_batch.where('NOT emails_disabled IS NULL').pluck(:id, :emails_disabled)
          next if plucked_list.empty?

          ApplicationRecord.connection.execute <<~SQL
                  UPDATE namespace_settings
                  SET emails_enabled= NOT subquery.emails_enabled
                  FROM (SELECT * FROM (#{Arel::Nodes::ValuesList.new(plucked_list).to_sql}) AS updates(namespace_id, emails_enabled)) AS subquery
                  WHERE namespace_settings.namespace_id=subquery.namespace_id
          SQL
        end
      end
    end
  end
end
