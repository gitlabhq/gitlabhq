# frozen_string_literal: true

class AddDiscordToUserDetails < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  # rubocop:disable Migration/AddLimitToTextColumns
  # limits are added in 20221128165833_add_discord_field_limit_to_user_details.rb
  def change
    add_column :user_details, :discord, :text, default: '', null: false
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
