# frozen_string_literal: true

class AddRegistrySettingsToApplicationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # rubocop:disable Migration/AddLimitToTextColumns
  def up
    add_column_with_default(:application_settings, # rubocop:disable Migration/AddColumnWithDefault
                            :container_registry_vendor,
                            :text,
                            default: '',
                            allow_null: false)

    add_column_with_default(:application_settings, # rubocop:disable Migration/AddColumnWithDefault
                            :container_registry_version,
                            :text,
                            default: '',
                            allow_null: false)
  end
  # rubocop:enable Migration/AddLimitToTextColumns

  def down
    remove_column :application_settings, :container_registry_vendor
    remove_column :application_settings, :container_registry_version
  end
end
