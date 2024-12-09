# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillFreeSharedRunnersMinutesLimit < BatchedMigrationJob
      feature_category :consumables_cost_management

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillFreeSharedRunnersMinutesLimit.prepend_mod
