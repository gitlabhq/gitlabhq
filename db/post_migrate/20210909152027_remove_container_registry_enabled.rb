# frozen_string_literal: true

class RemoveContainerRegistryEnabled < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_column :projects, :container_registry_enabled
    end
  end

  def down
    with_lock_retries do
      add_column :projects, :container_registry_enabled, :boolean # rubocop:disable Migration/AddColumnsToWideTables
    end
  end
end
