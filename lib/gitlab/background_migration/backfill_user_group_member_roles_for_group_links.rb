# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This batched background migration is EE-only,
    # Migration file - ee/lib/gitlab/background_migration/backfill_user_group_member_roles_for_group_links.rb

    class BackfillUserGroupMemberRolesForGroupLinks < BatchedMigrationJob
      feature_category :permissions

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillUserGroupMemberRolesForGroupLinks.prepend_mod
