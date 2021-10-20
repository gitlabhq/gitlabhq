# frozen_string_literal: true

class AddPhoneToUserDetails < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  # rubocop:disable Migration/AddLimitToTextColumns
  def up
    add_column :user_details, :phone, :text, comment: 'JiHu-specific column'
  end
  # rubocop:enable Migration/AddLimitToTextColumns

  def down
    remove_column :user_details, :phone
  end
end
