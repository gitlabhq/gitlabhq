# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDetectedAtToFindings < BatchedMigrationJob
      operation_name :backfill_detected_at_to_findings
      feature_category :vulnerability_management

      def perform
        each_sub_batch do |vulnerability_occurrences|
          connection.exec_update(<<~SQL)
            UPDATE
              vulnerability_occurrences
            SET
              detected_at = vulnerabilities.detected_at
            FROM
              vulnerabilities
            WHERE
              vulnerability_occurrences.vulnerability_id = vulnerabilities.id AND
              vulnerability_occurrences.detected_at IS NULL AND
              vulnerability_occurrences.id IN (#{vulnerability_occurrences.select(:id).to_sql})
          SQL
        end
      end
    end
  end
end
