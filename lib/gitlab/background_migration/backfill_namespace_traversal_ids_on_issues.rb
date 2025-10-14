# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillNamespaceTraversalIdsOnIssues < BatchedMigrationJob
      operation_name :backfill_namespace_traversal_ids_on_issues
      feature_category :portfolio_management

      def perform
        each_sub_batch do |sub_batch|
          connection.exec_update(update_sql(sub_batch))
        end
      end

      private

      def update_sql(sub_batch)
        <<~SQL
        UPDATE
          issues
        SET
          namespace_traversal_ids = namespaces.traversal_ids
        FROM
          namespaces
        WHERE
          namespaces.id = issues.namespace_id
          AND issues.id IN (#{sub_batch.select(:id).to_sql})
        SQL
      end
    end
  end
end
