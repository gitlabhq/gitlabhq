# frozen_string_literal: true

class AddRegistryMigrationApplicationSettings < Gitlab::Database::Migration[1.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20220118141950_add_text_limit_to_container_registry_import_target_plan.rb
  def change
    add_column :application_settings, :container_registry_import_max_tags_count, :integer, default: 100, null: false
    add_column :application_settings, :container_registry_import_max_retries, :integer, default: 3, null: false
    add_column :application_settings, :container_registry_import_start_max_retries, :integer, default: 50, null: false
    add_column :application_settings, :container_registry_import_max_step_duration, :integer, default: 5.minutes, null: false
    add_column :application_settings, :container_registry_import_target_plan, :text, default: 'free', null: false
    add_column :application_settings, :container_registry_import_created_before, :datetime_with_timezone, default: '2022-01-23 00:00:00', null: false
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
