# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillProjectNamespaceDetails < ::Gitlab::BackgroundMigration::BatchedMigrationJob
      operation_name :backfill_project_namespace_details
      feature_category :groups_and_projects

      def perform
        each_sub_batch do |sub_batch|
          upsert_project_namespace_details(sub_batch)
        end
      end

      def upsert_project_namespace_details(relation)
        connection.execute(
          <<~SQL
          INSERT INTO namespace_details (description, description_html, cached_markdown_version, created_at, updated_at, namespace_id)
            SELECT projects.description, projects.description_html, projects.cached_markdown_version, now(), now(), projects.project_namespace_id
            FROM projects
            WHERE projects.id IN(#{relation.select(:id).to_sql})
              AND projects.project_namespace_id IS NOT NULL
          ON CONFLICT (namespace_id) DO UPDATE SET
            description = EXCLUDED.description,
            description_html = EXCLUDED.description_html,
            cached_markdown_version = EXCLUDED.cached_markdown_version,
            updated_at = EXCLUDED.updated_at;
          SQL
        )
      end
    end
  end
end
