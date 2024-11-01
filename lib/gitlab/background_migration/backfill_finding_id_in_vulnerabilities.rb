# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfills vulnerabilities.finding_id column based on vulnerability_occurrences.vulnerability_id column
    class BackfillFindingIdInVulnerabilities < BatchedMigrationJob
      operation_name :backfill_finding_id_in_vulnerabilities_table
      scope_to ->(relation) { relation.where(finding_id: nil) }
      feature_category :vulnerability_management

      class VulnerabilitiesFindings < ApplicationRecord
        self.table_name = "vulnerability_occurrences"
      end

      def perform
        each_sub_batch do |sub_batch|
          connection.execute <<~SQL
            UPDATE vulnerabilities
            SET finding_id = vulnerability_occurrences.id
            FROM vulnerability_occurrences
            WHERE vulnerabilities.id IN (#{sub_batch.select(:id).to_sql})
            AND vulnerabilities.id = vulnerability_occurrences.vulnerability_id
          SQL
        end
      end
    end
  end
end
