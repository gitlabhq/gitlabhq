# frozen_string_literal: true

class AddBulkImportExportsTableIndexes < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  GROUP_INDEX_NAME = 'partial_index_bulk_import_exports_on_group_id_and_relation'
  PROJECT_INDEX_NAME = 'partial_index_bulk_import_exports_on_project_id_and_relation'

  def up
    add_concurrent_index :bulk_import_exports,
                         [:group_id, :relation],
                         unique: true,
                         where: 'group_id IS NOT NULL',
                         name: GROUP_INDEX_NAME

    add_concurrent_index :bulk_import_exports,
                         [:project_id, :relation],
                         unique: true,
                         where: 'project_id IS NOT NULL',
                         name: PROJECT_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name(:bulk_import_exports, GROUP_INDEX_NAME)
    remove_concurrent_index_by_name(:bulk_import_exports, PROJECT_INDEX_NAME)
  end
end
