# frozen_string_literal: true

class AddBlueskyToUserDetails < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  USER_DETAILS_FIELD_LIMIT = 256

  def up
    with_lock_retries do
      add_column :user_details, :bluesky, :text, default: '', null: false, if_not_exists: true
    end

    add_text_limit :user_details, :bluesky, USER_DETAILS_FIELD_LIMIT
  end

  def down
    with_lock_retries do
      remove_column :user_details, :bluesky
    end
  end
end
