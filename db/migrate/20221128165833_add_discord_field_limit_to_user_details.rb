# frozen_string_literal: true

class AddDiscordFieldLimitToUserDetails < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  USER_DETAILS_FIELD_LIMIT = 500

  def up
    add_text_limit :user_details, :discord, USER_DETAILS_FIELD_LIMIT
  end

  def down
    remove_text_limit :user_details, :discord
  end
end
