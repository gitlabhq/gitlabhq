# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSbomOccurrencesTraversalIdsAndArchived < BatchedMigrationJob
      feature_category :dependency_management
      operation_name :backfill_sbom_occurrences_traversal_ids_and_archived

      def perform
        each_sub_batch do |relation|
          batch_start_id, batch_end_id = relation.pick(Arel.sql("MIN(#{batch_column}), MAX(#{batch_column})"))
          connection.exec_update(update_sql(batch_start_id, batch_end_id))
        end
      end

      private

      def update_sql(batch_start_id, batch_end_id)
        <<~SQL
        UPDATE
          sbom_occurrences
        SET
          traversal_ids = namespaces.traversal_ids,
          archived = projects.archived
        FROM
          projects JOIN namespaces ON namespaces.id = projects.namespace_id
        WHERE
          sbom_occurrences.project_id = projects.id AND
          sbom_occurrences.id >= #{batch_start_id} AND
          sbom_occurrences.id <= #{batch_end_id}
        SQL
      end
    end
  end
end
