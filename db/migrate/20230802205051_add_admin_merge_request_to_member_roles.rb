# frozen_string_literal: true

class AddAdminMergeRequestToMemberRoles < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    return if column_exists?(:member_roles, :admin_merge_request)

    add_column :member_roles, :admin_merge_request, :boolean, default: false, null: false
  end

  def down
    return unless column_exists?(:member_roles, :admin_merge_request)

    remove_column :member_roles, :admin_merge_request
  end
end
