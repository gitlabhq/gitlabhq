# frozen_string_literal: true

class IndexPackagesDebianGroupComponentFilesOnGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_debian_group_component_files_on_group_id'

  def up
    add_concurrent_index :packages_debian_group_component_files, :group_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_debian_group_component_files, INDEX_NAME
  end
end
