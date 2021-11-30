# frozen_string_literal: true
class AddTextLimitForStaticObjectsExternalStorageAuthToken < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :static_objects_external_storage_auth_token_encrypted, 255
  end

  def down
    remove_text_limit :application_settings, :static_objects_external_storage_auth_token_encrypted
  end
end
