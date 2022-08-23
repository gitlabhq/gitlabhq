# frozen_string_literal: true

class RemoveOtherRoleFromUserDetails < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    remove_column :user_details, :other_role, :text
  end
end
