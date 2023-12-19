# frozen_string_literal: true

class AddIndexServiceDeskSettingsOnCustomEmailEnabled < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  INDEX_NAME = 'index_service_desk_settings_on_custom_email_enabled'

  def up
    add_concurrent_index :service_desk_settings, :custom_email_enabled, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :service_desk_settings, INDEX_NAME
  end
end
