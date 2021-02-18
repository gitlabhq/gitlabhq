# frozen_string_literal: true

class AddOrphanIndexToComposerCacheFiles < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_composer_cache_files_where_namespace_id_is_null'

  def up
    add_concurrent_index :packages_composer_cache_files, :id, name: INDEX_NAME, where: 'namespace_id IS NULL'
  end

  def down
    remove_concurrent_index_by_name :packages_composer_cache_files, INDEX_NAME
  end
end
