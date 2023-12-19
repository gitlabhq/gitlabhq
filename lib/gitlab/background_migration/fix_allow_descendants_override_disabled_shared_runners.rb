# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Fixes invalid combination of shared runners being enabled and
    # allow_descendants_override = true
    # This combination fails validation and doesn't make sense:
    # we always allow descendants to disable shared runners
    class FixAllowDescendantsOverrideDisabledSharedRunners < BatchedMigrationJob
      feature_category :fleet_visibility
      operation_name :fix_allow_descendants_override_disabled_shared_runners

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where(shared_runners_enabled: true,
            allow_descendants_override_disabled_shared_runners: true)
            .update_all(allow_descendants_override_disabled_shared_runners: false)
        end
      end
    end
  end
end
