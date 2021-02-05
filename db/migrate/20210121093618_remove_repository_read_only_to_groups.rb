# frozen_string_literal: true

class RemoveRepositoryReadOnlyToGroups < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    if column_exists?(:namespaces, :repository_read_only)
      with_lock_retries do
        remove_column :namespaces, :repository_read_only # rubocop:disable Migration/RemoveColumn
      end
    end
  end

  def down
    unless column_exists?(:namespaces, :repository_read_only)
      with_lock_retries do
        add_column :namespaces, :repository_read_only, :boolean, default: false, null: false # rubocop:disable Migration/AddColumnsToWideTables
      end
    end
  end
end
