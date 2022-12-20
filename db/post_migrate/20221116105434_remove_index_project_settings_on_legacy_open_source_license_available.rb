# frozen_string_literal: true

class RemoveIndexProjectSettingsOnLegacyOpenSourceLicenseAvailable < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_project_settings_on_legacy_open_source_license_available'

  def up
    remove_concurrent_index_by_name(:project_settings, INDEX_NAME)
  end

  def down
    add_concurrent_index :project_settings,
                         %i[legacy_open_source_license_available],
                         where: "legacy_open_source_license_available = TRUE",
                         name: INDEX_NAME
  end
end
