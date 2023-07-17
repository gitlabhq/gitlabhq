# frozen_string_literal: true

class AddNamespaceStorageForksCostFactorToApplicationSettings < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_app_settings_namespace_storage_forks_cost_factor_range'

  def up
    with_lock_retries do
      add_column :application_settings, :namespace_storage_forks_cost_factor,
        :float, default: 1.0, null: false, if_not_exists: true
    end

    add_check_constraint :application_settings,
      'namespace_storage_forks_cost_factor >= 0 AND namespace_storage_forks_cost_factor <= 1',
      CONSTRAINT_NAME
  end

  def down
    remove_column :application_settings, :namespace_storage_forks_cost_factor
  end
end
