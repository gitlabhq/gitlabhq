# frozen_string_literal: true

class DropContainerRegistryDataRepairDetailWorkerMaxConcurrencySettingsColumn < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  CONSTRAINT_NAME = 'app_settings_registry_repair_worker_max_concurrency_positive'

  def up
    remove_column :application_settings, :container_registry_data_repair_detail_worker_max_concurrency
  end

  def down
    add_column(
      :application_settings,
      :container_registry_data_repair_detail_worker_max_concurrency,
      :integer,
      default: 2,
      null: false,
      if_not_exists: true
    )

    add_check_constraint(
      :application_settings,
      'container_registry_data_repair_detail_worker_max_concurrency >= 0',
      CONSTRAINT_NAME
    )
  end
end
