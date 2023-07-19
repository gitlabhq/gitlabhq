# frozen_string_literal: true

class RemoveUserDetailsProvisionedByGroupAtColumn < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    remove_column :user_details, :provisioned_by_group_at, :datetime_with_timezone
  end
end
