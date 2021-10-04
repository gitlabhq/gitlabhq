# frozen_string_literal: true

class RemoveDelayedProjectRemovalFromNamespaces < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_column :namespaces, :delayed_project_removal
    end
  end

  def down
    with_lock_retries do
      add_column :namespaces, :delayed_project_removal, :boolean, default: false, null: false, if_not_exists: true # rubocop:disable Migration/AddColumnsToWideTables
    end

    add_concurrent_index :namespaces, :id, name: 'tmp_idx_on_namespaces_delayed_project_removal', where: 'delayed_project_removal = TRUE'
  end
end
