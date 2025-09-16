# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillUserGroupMemberRoles < BatchedMigrationJob
      feature_category :permissions

      # This batched background migration is EE-only,
      # Migration file - ee/lib/gitlab/background_migration/backfill_user_group_member_roles.rb

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillUserGroupMemberRoles.prepend_mod
