# frozen_string_literal: true

class AddEncryptedStaticObjectToken < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    # rubocop:disable Migration/AddLimitToTextColumns
    # limit is added in 20211126142354_add_text_limit_to_encrypted_static_object_token
    add_column :users, :static_object_token_encrypted, :text # rubocop:disable Migration/AddColumnsToWideTables
    # rubocop:enable Migration/AddLimitToTextColumns
  end

  def down
    remove_column :users, :static_object_token_encrypted
  end
end
