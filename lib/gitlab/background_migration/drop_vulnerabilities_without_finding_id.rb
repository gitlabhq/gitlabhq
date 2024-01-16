# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DropVulnerabilitiesWithoutFindingId < BatchedMigrationJob
      operation_name :drop_vulnerabilities_without_finding_id
      scope_to ->(relation) { relation.where(finding_id: nil) }
      feature_category :vulnerability_management

      def perform
        each_sub_batch(&:delete_all)
      end
    end
  end
end
