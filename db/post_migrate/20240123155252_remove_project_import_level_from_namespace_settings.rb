# frozen_string_literal: true

class RemoveProjectImportLevelFromNamespaceSettings < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  enable_lock_retries!

  def change
    remove_column :namespace_settings, :project_import_level, :smallint, default: 50, null: false
  end
end
