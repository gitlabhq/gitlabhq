# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillEpicsWorkItemParentLinkId < BatchedMigrationJob
      feature_category :team_planning

      def perform
        # no-op. The logic is defined in EE module
      end
    end
  end
end
# rubocop:disable Layout/LineLength -- prepend statement is too long
Gitlab::BackgroundMigration::BackfillEpicsWorkItemParentLinkId.prepend_mod_with('Gitlab::BackgroundMigration::BackfillEpicsWorkItemParentLinkId')
# rubocop:enable Layout/LineLength
