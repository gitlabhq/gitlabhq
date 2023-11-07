# frozen_string_literal: true

class AddIndexToPackagesTagsProjectId < Gitlab::Database::Migration[2.2]
  milestone '16.6'
  disable_ddl_transaction!
  INDEX_NAME = :index_packages_tags_on_project_id

  def up
    add_concurrent_index :packages_tags, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name(:packages_tags, INDEX_NAME)
  end
end
