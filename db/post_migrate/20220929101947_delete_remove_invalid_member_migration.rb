# frozen_string_literal: true

class DeleteRemoveInvalidMemberMigration < Gitlab::Database::Migration[2.0]
  PROJECT_MEMBER_MIGRATION = 'ScheduleDestroyInvalidProjectMembers'
  GROUP_MEMBER_MIGRATION = 'ScheduleDestroyInvalidGroupMembers'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    delete_batched_background_migration(PROJECT_MEMBER_MIGRATION, :members, :id, [])
    delete_batched_background_migration(GROUP_MEMBER_MIGRATION, :members, :id, [])
  end

  def down
    # no-op
  end
end
