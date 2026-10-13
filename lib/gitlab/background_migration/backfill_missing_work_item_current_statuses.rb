# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Statuses are EE-only; the implementation lives in the EE module.
    class BackfillMissingWorkItemCurrentStatuses < BatchedMigrationJob
      cursor :id

      feature_category :team_planning
      tables_to_check_for_vacuum :work_item_current_statuses

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillMissingWorkItemCurrentStatuses.prepend_mod
