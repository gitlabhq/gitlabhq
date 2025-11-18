# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMissingNamespaceDetails < BatchedMigrationJob
      operation_name :backfill_missing_namespace_details
      feature_category :groups_and_projects

      def perform
        each_sub_batch do |sub_batch|
          insert_namespace_details(sub_batch)
        end
      end

      private

      def insert_namespace_details(sub_batch)
        connection.execute(<<~SQL)
          INSERT INTO namespace_details (description, description_html, cached_markdown_version, created_at, updated_at, namespace_id)
          SELECT n.description, n.description_html, n.cached_markdown_version, NOW(), NOW(), n.id
          FROM namespaces n
          WHERE n.id IN (#{sub_batch.select(:id).to_sql})
            AND NOT EXISTS (
              SELECT 1 FROM namespace_details nd
              WHERE nd.namespace_id = n.id
            )
        SQL
      end
    end
  end
end
