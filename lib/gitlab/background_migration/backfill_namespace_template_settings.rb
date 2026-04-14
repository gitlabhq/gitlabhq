# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillNamespaceTemplateSettings < BatchedMigrationJob
      operation_name :backfill_namespace_template_settings
      feature_category :groups_and_projects

      def perform
        each_sub_batch do |sub_batch|
          upsert_namespace_template_settings(sub_batch)
        end
      end

      private

      def upsert_namespace_template_settings(sub_batch)
        connection.execute(<<~SQL)
          INSERT INTO namespace_template_settings (namespace_id, file_template_project_id, custom_project_templates_group_id, created_at, updated_at)
          SELECT n.id, n.file_template_project_id, n.custom_project_templates_group_id, NOW(), NOW()
          FROM namespaces n
          INNER JOIN (#{sub_batch.select(:id).to_sql}) AS batch(id) ON batch.id = n.id
          WHERE n.file_template_project_id IS NOT NULL OR n.custom_project_templates_group_id IS NOT NULL
          ON CONFLICT (namespace_id) DO NOTHING
        SQL
      end
    end
  end
end
