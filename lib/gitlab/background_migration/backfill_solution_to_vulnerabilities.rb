# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSolutionToVulnerabilities < BatchedMigrationJob
      operation_name :backfill_solution_to_vulnerabilities
      feature_category :vulnerability_management

      def perform
        each_sub_batch do |sub_batch|
          update(sub_batch)
        end
      end

      private

      def update(sub_batch)
        ::SecApplicationRecord.connection.exec_update(update_sql(sub_batch))
      end

      def update_sql(sub_batch)
        <<~SQL
        UPDATE
          vulnerabilities
        SET
          solution = vulnerability_occurrences.solution
        FROM
          vulnerability_occurrences
        WHERE
          vulnerability_occurrences.vulnerability_id IN (#{sub_batch.select(:id).to_sql}) AND
          vulnerability_occurrences.vulnerability_id = vulnerabilities.id AND
          vulnerabilities.solution IS NULL AND
          vulnerability_occurrences.solution IS NOT NULL
        SQL
      end
    end
  end
end
