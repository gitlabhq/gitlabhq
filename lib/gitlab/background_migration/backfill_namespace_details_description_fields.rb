# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillNamespaceDetailsDescriptionFields < BatchedMigrationJob
      operation_name :backfill_namespace_details_description_fields
      feature_category :groups_and_projects

      def perform
        each_sub_batch do |sub_batch|
          backfill_namespace_details_fields(sub_batch)
        end
      end

      private

      def backfill_namespace_details_fields(relation)
        connection.execute(<<~SQL)
          UPDATE namespace_details
          SET description = CASE WHEN namespace_details.description IS NULL THEN namespaces.description ELSE namespace_details.description END,
              description_html = CASE WHEN namespace_details.description_html IS NULL THEN namespaces.description_html ELSE namespace_details.description_html END,
              cached_markdown_version = CASE WHEN namespace_details.cached_markdown_version IS NULL THEN namespaces.cached_markdown_version ELSE namespace_details.cached_markdown_version END
          FROM namespaces
          WHERE namespace_details.namespace_id = namespaces.id
            AND namespace_details.namespace_id IN (#{relation.select(:namespace_id).to_sql})
            AND (
              (namespace_details.description IS NULL AND namespaces.description IS NOT NULL)
              OR (namespace_details.description_html IS NULL AND namespaces.description_html IS NOT NULL)
              OR (namespace_details.cached_markdown_version IS NULL AND namespaces.cached_markdown_version IS NOT NULL)
            )
        SQL
      end
    end
  end
end
