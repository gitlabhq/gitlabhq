# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class ResyncHasVulnerabilities < BatchedMigrationJob
      operation_name :rsync_has_vulnerabilities
      feature_category :vulnerability_management

      class Vulnerability < Database::SecApplicationRecord
        self.table_name = 'vulnerabilities'
      end

      class ProjectSetting < ApplicationRecord
        self.table_name = 'project_settings'
      end

      def perform
        each_sub_batch do |sub_batch|
          project_ids = sub_batch.pluck(:project_id)
          bulk_update!(update_values_sql(project_ids))
        end
      end

      private

      def update_values_sql(project_ids)
        project_ids_values = Arel::Nodes::ValuesList.new(project_ids.zip).to_sql

        results = Vulnerability
          .select('project_ids.id AS project_id', exists_select)
          .from("(#{project_ids_values}) AS project_ids (id)")

        update_values = results.map { |result| [result.project_id, result.has_vulnerabilities] }
        Arel::Nodes::ValuesList.new(update_values).to_sql
      end

      def exists_select
        <<~SQL
          EXISTS (
            SELECT
                1
            FROM
                vulnerabilities
            WHERE
                vulnerabilities.project_id = project_ids.id AND
                vulnerabilities.present_on_default_branch IS TRUE
          ) AS has_vulnerabilities
        SQL
      end

      def bulk_update!(update_values)
        sql = <<~SQL
          UPDATE
            project_settings
          SET
            has_vulnerabilities = update_values.has_vulnerabilities,
            updated_at = NOW()
          FROM
            (#{update_values}) AS update_values (project_id, has_vulnerabilities)
          WHERE
            project_settings.project_id = update_values.project_id;
        SQL

        ProjectSetting.connection.execute(sql)
      end
    end
  end
end
