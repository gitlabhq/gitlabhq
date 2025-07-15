# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/database/batched_background_migrations.html
# for more information on how to use batched background migrations

# Update below commented lines with appropriate values.

module Gitlab
  module BackgroundMigration
    class BackfillEpicIssuesWorkItemParentLinkId < BatchedMigrationJob
      feature_category :team_planning

      def perform
        # no-op. Logic is defined in EE module
      end
    end
  end
end
# rubocop:disable Layout/LineLength -- prepend statement is too long
Gitlab::BackgroundMigration::BackfillEpicIssuesWorkItemParentLinkId.prepend_mod_with('Gitlab::BackgroundMigration::BackfillEpicIssuesWorkItemParentLinkId')
# rubocop:enable Layout/LineLength
