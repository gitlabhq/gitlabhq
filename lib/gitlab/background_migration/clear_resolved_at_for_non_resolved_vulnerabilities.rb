# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class ClearResolvedAtForNonResolvedVulnerabilities < BatchedMigrationJob
      RESOLVED_STATE = 3

      operation_name :clear_resolved_at_for_non_resolved_vulnerabilities
      feature_category :vulnerability_management

      def perform
        each_sub_batch do |sub_batch|
          non_resolved = sub_batch.where.not(state: RESOLVED_STATE)

          non_resolved
            .where.not(resolved_at: nil)
            .or(non_resolved.where.not(resolved_by_id: nil))
            .update_all(resolved_at: nil, resolved_by_id: nil)
        end
      end
    end
  end
end
