# frozen_string_literal: true

class AddContainerRegistryDataRepairWorkerMaxConcurrencyToApplicationSettings < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'app_settings_registry_repair_worker_max_concurrency_positive'

  def up
    unless column_exists?(:application_settings, :container_registry_data_repair_detail_worker_max_concurrency)
      add_column :application_settings, :container_registry_data_repair_detail_worker_max_concurrency, :integer,
        default: 2, null: false
    end

    add_check_constraint :application_settings,
      'container_registry_data_repair_detail_worker_max_concurrency >= 0',
      CONSTRAINT_NAME
  end

  def down
    return unless column_exists?(:application_settings, :container_registry_data_repair_detail_worker_max_concurrency)

    remove_check_constraint :application_settings, CONSTRAINT_NAME

    remove_column :application_settings, :container_registry_data_repair_detail_worker_max_concurrency
  end
end
