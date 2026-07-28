# frozen_string_literal: true

class AddServiceDeskSettingsCustomEmailOrProjectKeyPresentIndex < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'idx_service_desk_settings_where_custom_email_or_project_key'

  disable_ddl_transaction!
  milestone '19.3'

  def up
    add_concurrent_index :service_desk_settings,
      :project_id,
      name: INDEX_NAME,
      where: 'custom_email IS NOT NULL OR project_key IS NOT NULL'
  end

  def down
    remove_concurrent_index :service_desk_settings, :project_id, name: INDEX_NAME
  end
end
