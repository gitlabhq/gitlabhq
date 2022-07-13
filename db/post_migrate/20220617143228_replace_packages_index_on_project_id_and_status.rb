# frozen_string_literal: true

class ReplacePackagesIndexOnProjectIdAndStatus < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  NEW_INDEX_NAME = 'index_packages_packages_on_project_id_and_status_and_id'
  OLD_INDEX_NAME = 'index_packages_packages_on_project_id_and_status'

  def up
    add_concurrent_index :packages_packages,
                         [:project_id, :status, :id],
                         name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :packages_packages, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :packages_packages,
                         [:project_id, :status],
                         name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :packages_packages, NEW_INDEX_NAME
  end
end
