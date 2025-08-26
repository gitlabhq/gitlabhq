# frozen_string_literal: true

class QueueBackfillUserGroupMemberRoles < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillUserGroupMemberRoles"

  def up
    # no-op because there was a bug in the original migration, which has been
    # fixed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202181
  end

  def down
    # no-op because there was a bug in the original migration, which has been
    # fixed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202181
  end
end
