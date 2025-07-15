# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillRolledUpWeightForWorkItems < BatchedMigrationJob
      operation_name :backfill_rolled_up_weight_for_work_items
      feature_category :team_planning

      def perform
        # This is a no-op in CE. The actual implementation is in EE.
      end
    end
  end
end

Gitlab::BackgroundMigration::BackfillRolledUpWeightForWorkItems.prepend_mod
