# frozen_string_literal: true

class RemoveDeactivatedUserHighestRoleStats < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # This migration is applicable to self-managed instances that may utilize the
    # dormant user deactivation feature. This feature is not enabled on Gitlab.com.
    return if Gitlab.com?

    users_table = define_batchable_model('users')
    user_highest_roles_table = define_batchable_model('user_highest_roles')

    users_table.where(state: 'deactivated').each_batch do |users_batch|
      user_ids = users_batch.pluck(:id)
      user_highest_roles_table.where(user_id: user_ids).delete_all
    end
  end

  def down
    # no-op

    # This migration removes entries from the UserHighestRole table and cannot be reversed
  end
end
