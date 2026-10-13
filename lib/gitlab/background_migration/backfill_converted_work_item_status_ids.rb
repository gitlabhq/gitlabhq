# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Statuses are EE-only; the implementation lives in the EE module.
    class BackfillConvertedWorkItemStatusIds < BatchedMigrationJob
      cursor :id

      feature_category :team_planning

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillConvertedWorkItemStatusIds.prepend_mod
