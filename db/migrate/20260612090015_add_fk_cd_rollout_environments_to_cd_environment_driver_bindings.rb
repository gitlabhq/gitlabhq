# frozen_string_literal: true

class AddFkCdRolloutEnvironmentsToCdEnvironmentDriverBindings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  def up
    add_concurrent_foreign_key :cd_rollout_environments, :cd_environment_driver_bindings,
      column: :driver_binding_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :cd_rollout_environments, column: :driver_binding_id
    end
  end
end
