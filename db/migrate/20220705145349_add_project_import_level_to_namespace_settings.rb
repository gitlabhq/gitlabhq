# frozen_string_literal: true

class AddProjectImportLevelToNamespaceSettings < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :namespace_settings, :project_import_level, :smallint, default: 0, null: false
  end
end
