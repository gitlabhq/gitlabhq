# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesProtectionRules < BatchedMigrationJob
      feature_category :package_registry
      operation_name :backfill_packages_protection_rules

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where(pattern: nil).update_all(
            'pattern = package_name_pattern, pattern_type = 0, target_field = 0'
          )
        end
      end
    end
  end
end
