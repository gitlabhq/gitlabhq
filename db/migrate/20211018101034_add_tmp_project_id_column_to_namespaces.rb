# frozen_string_literal: true

class AddTmpProjectIdColumnToNamespaces < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    # this is a temporary column to be able to batch insert records into namespaces table and then be able to link these
    # to projects table.
    add_column :namespaces, :tmp_project_id, :integer # rubocop: disable Migration/AddColumnsToWideTables
  end
end
