# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Seeds refs that have no reachability yet with their occurrence's value. The occurrence value
    # is whichever ref was ingested last, so a non-default ref can be wrong until its next pipeline
    # rewrites it. Refs already written by ingestion are left alone.
    class BackfillSbomOccurrenceRefsReachability < BatchedMigrationJob
      cursor :id

      operation_name :backfill_sbom_occurrence_refs_reachability
      feature_category :dependency_management

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(<<~SQL)
            UPDATE sbom_occurrence_refs
            SET reachability = sbom_occurrences.reachability
            FROM sbom_occurrences
            WHERE sbom_occurrences.id = sbom_occurrence_refs.sbom_occurrence_id
              AND sbom_occurrence_refs.id IN (#{sub_batch.select(:id).to_sql})
              AND sbom_occurrence_refs.reachability IS NULL
              AND sbom_occurrences.reachability IS NOT NULL
          SQL
        end
      end
    end
  end
end
