# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill namespace_details for a range of namespaces
    class BackfillNamespaceDetails < ::Gitlab::BackgroundMigration::BatchedMigrationJob
      operation_name :backfill_namespace_details
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          upsert_namespace_details(sub_batch)
        end
      end

      def upsert_namespace_details(relation)
        connection.execute(
          <<~SQL
          INSERT INTO namespace_details (description, description_html, cached_markdown_version, created_at, updated_at, namespace_id)
            SELECT namespaces.description, namespaces.description_html, namespaces.cached_markdown_version, now(), now(), namespaces.id
            FROM namespaces
            WHERE namespaces.id IN(#{relation.select(:id).to_sql})
            AND namespaces.type <> 'Project'
          ON CONFLICT (namespace_id) DO NOTHING;
        SQL
        )
      end
    end
  end
end
