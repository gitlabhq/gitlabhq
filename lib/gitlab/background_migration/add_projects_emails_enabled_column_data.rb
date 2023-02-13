# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Iterates through the Projects table and attempts to set the
    # opposite of the value of the column "emails_disabled" to a new
    # column in project_settings called emails_enabled
    class AddProjectsEmailsEnabledColumnData < BatchedMigrationJob
      feature_category :database
      operation_name :add_projects_emails_enabled_column_data

      # Targeted table
      class ProjectSetting < ApplicationRecord
        self.table_name = 'project_settings'
      end

      def perform
        each_sub_batch do |sub_batch|
          plucked_list = sub_batch.where('NOT emails_disabled IS NULL').pluck(:id, :emails_disabled)
          next if plucked_list.empty?

          ApplicationRecord.connection.execute <<~SQL
                  UPDATE project_settings
                  SET emails_enabled=NOT subquery.emails_enabled
                  FROM (SELECT * FROM (#{Arel::Nodes::ValuesList.new(plucked_list).to_sql}) AS updates(project_id, emails_enabled)) AS subquery
                  WHERE project_settings.project_id=subquery.project_id
          SQL
        end
      end
    end
  end
end
