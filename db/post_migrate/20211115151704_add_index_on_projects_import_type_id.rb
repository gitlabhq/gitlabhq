# frozen_string_literal: true

class AddIndexOnProjectsImportTypeId < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_imported_projects_on_import_type_id'

  def up
    add_concurrent_index(:projects, [:import_type, :id], where: 'import_type IS NOT NULL', name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:projects, INDEX_NAME)
  end
end
