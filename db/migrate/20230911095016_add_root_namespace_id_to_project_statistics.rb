# frozen_string_literal: true

class AddRootNamespaceIdToProjectStatistics < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = "index_project_statistics_on_root_namespace_id"

  def up
    unless column_exists?(:project_statistics, :root_namespace_id)
      add_column :project_statistics, :root_namespace_id, :bigint
    end

    add_concurrent_foreign_key :project_statistics, :namespaces,
      column: :root_namespace_id,
      on_delete: :nullify

    add_concurrent_index :project_statistics, :root_namespace_id, name: INDEX_NAME
  end

  def down
    return unless column_exists?(:project_statistics, :root_namespace_id)

    remove_column :project_statistics, :root_namespace_id, :bigint
  end
end
