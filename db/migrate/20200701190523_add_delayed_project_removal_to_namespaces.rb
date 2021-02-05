# frozen_string_literal: true

class AddDelayedProjectRemovalToNamespaces < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :namespaces, :delayed_project_removal, :boolean, default: false, null: false # rubocop:disable Migration/AddColumnsToWideTables
    end
  end

  def down
    with_lock_retries do
      remove_column :namespaces, :delayed_project_removal
    end
  end
end
