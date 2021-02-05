# frozen_string_literal: true

class AddTraversalIdsToNamespaces < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :namespaces, :traversal_ids, :integer, array: true, default: [], null: false # rubocop:disable Migration/AddColumnsToWideTables
    end
  end

  def down
    with_lock_retries do
      remove_column :namespaces, :traversal_ids
    end
  end
end
