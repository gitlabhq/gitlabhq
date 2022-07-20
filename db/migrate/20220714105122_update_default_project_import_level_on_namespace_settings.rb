# frozen_string_literal: true

class UpdateDefaultProjectImportLevelOnNamespaceSettings < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    change_column :namespace_settings, :project_import_level, :smallint, default: 50, null: false
  end

  def down
    change_column :namespace_settings, :project_import_level, :smallint, default: 0, null: false
  end
end
