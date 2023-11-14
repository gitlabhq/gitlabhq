# frozen_string_literal: true

class AddMastodonToUserDetails < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  USER_DETAILS_FIELD_LIMIT = 500

  def up
    with_lock_retries do
      add_column :user_details, :mastodon, :text, default: '', null: false, if_not_exists: true
    end

    add_text_limit :user_details, :mastodon, USER_DETAILS_FIELD_LIMIT
  end

  def down
    with_lock_retries do
      remove_column :user_details, :mastodon
    end
  end
end
