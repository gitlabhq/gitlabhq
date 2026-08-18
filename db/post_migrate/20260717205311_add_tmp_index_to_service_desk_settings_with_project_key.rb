# frozen_string_literal: true

class AddTmpIndexToServiceDeskSettingsWithProjectKey < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'tmp_idx_service_desk_settings_with_project_key'

  disable_ddl_transaction!
  milestone '19.3'

  def up
    add_concurrent_index :service_desk_settings, :project_id, name: INDEX_NAME, where: 'project_key IS NOT NULL'
  end

  def down
    remove_concurrent_index :service_desk_settings, :project_id, name: INDEX_NAME
  end
end
