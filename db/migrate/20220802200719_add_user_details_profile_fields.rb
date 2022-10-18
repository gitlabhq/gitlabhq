# frozen_string_literal: true

class AddUserDetailsProfileFields < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  # rubocop:disable Migration/AddLimitToTextColumns
  # limits are added in 20220802202505_add_user_details_field_limits
  def change
    add_column :user_details, :linkedin, :text, null: false, default: ''
    add_column :user_details, :twitter, :text, null: false, default: ''
    add_column :user_details, :skype, :text, null: false, default: ''
    add_column :user_details, :website_url, :text, null: false, default: ''
    add_column :user_details, :location, :text, null: false, default: ''
    add_column :user_details, :organization, :text, null: false, default: ''
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
