# frozen_string_literal: true

class AddEnterpriseColumnsToUserDetails < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :user_details, :enterprise_group_id, :bigint

    add_column :user_details, :enterprise_group_associated_at, :datetime_with_timezone
  end
end
