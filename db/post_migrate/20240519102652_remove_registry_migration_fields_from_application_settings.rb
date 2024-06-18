# frozen_string_literal: true

class RemoveRegistryMigrationFieldsFromApplicationSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.1'

  def up
    with_lock_retries do
      remove_column(:application_settings, :container_registry_import_max_tags_count)
      remove_column(:application_settings, :container_registry_import_max_retries)
      remove_column(:application_settings, :container_registry_import_start_max_retries)
      remove_column(:application_settings, :container_registry_import_max_step_duration)
      remove_column(:application_settings, :container_registry_pre_import_tags_rate)
      remove_column(:application_settings, :container_registry_pre_import_timeout)
      remove_column(:application_settings, :container_registry_import_timeout)
      remove_column(:application_settings, :container_registry_import_target_plan)
      remove_column(:application_settings, :container_registry_import_created_before)
    end
  end

  def down
    with_lock_retries do
      add_column :application_settings, :container_registry_import_max_tags_count,
        :integer, default: 100, null: false, if_not_exists: true
      add_column :application_settings, :container_registry_import_max_retries,
        :integer, default: 3, null: false, if_not_exists: true
      add_column :application_settings, :container_registry_import_start_max_retries,
        :integer, default: 50, null: false, if_not_exists: true
      add_column :application_settings, :container_registry_import_max_step_duration,
        :integer, default: 5.minutes, null: false, if_not_exists: true
      add_column :application_settings, :container_registry_pre_import_tags_rate,
        :decimal, precision: 6, scale: 2, default: 0.5, null: false, if_not_exists: true
      add_column :application_settings, :container_registry_pre_import_timeout,
        :integer, default: 30.minutes, null: false, if_not_exists: true
      add_column :application_settings, :container_registry_import_timeout,
        :integer, default: 10.minutes, null: false, if_not_exists: true
      add_column :application_settings, :container_registry_import_target_plan,
        :text, default: 'free', null: false, if_not_exists: true
      add_column :application_settings, :container_registry_import_created_before,
        :datetime_with_timezone, default: '2022-01-23 00:00:00+00', null: false, if_not_exists: true
    end

    add_text_limit :application_settings, :container_registry_import_target_plan, 255
    add_check_constraint :application_settings,
      'container_registry_pre_import_tags_rate >= 0::numeric',
      'app_settings_container_registry_pre_import_tags_rate_positive'
  end
end
