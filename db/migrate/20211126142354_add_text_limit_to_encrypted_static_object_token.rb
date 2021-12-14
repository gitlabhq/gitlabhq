# frozen_string_literal: true

class AddTextLimitToEncryptedStaticObjectToken < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :users, :static_object_token_encrypted, 255
  end

  def down
    remove_text_limit :users, :static_object_token_encrypted
  end
end
