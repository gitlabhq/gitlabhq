# frozen_string_literal: true

class AddEncryptedStaticObjectsExternalStorageAuthToken < Gitlab::Database::Migration[1.0]
  def up
    # rubocop:disable Migration/AddLimitToTextColumns
    # limit is added in 20211126113029_add_text_limit_for_static_objects_external_storage_auth_token
    add_column :application_settings, :static_objects_external_storage_auth_token_encrypted, :text
    # rubocop:enable Migration/AddLimitToTextColumns
  end

  def down
    remove_column :application_settings, :static_objects_external_storage_auth_token_encrypted
  end
end
