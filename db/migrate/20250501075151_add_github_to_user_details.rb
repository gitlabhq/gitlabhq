# frozen_string_literal: true

class AddGithubToUserDetails < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.0'

  USER_DETAILS_FIELD_LIMIT = 500

  def up
    with_lock_retries do
      add_column :user_details, :github, :text, default: '', null: false, if_not_exists: true
    end

    add_text_limit :user_details, :github, USER_DETAILS_FIELD_LIMIT
  end

  def down
    with_lock_retries do
      remove_column :user_details, :github
    end
  end
end
