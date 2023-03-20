# frozen_string_literal: true

class AddProvisionedByGroupAtToUserDetails < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :user_details, :provisioned_by_group_at, :datetime_with_timezone
  end
end
