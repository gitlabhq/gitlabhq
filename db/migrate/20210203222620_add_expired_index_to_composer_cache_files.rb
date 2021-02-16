# frozen_string_literal: true

class AddExpiredIndexToComposerCacheFiles < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'composer_cache_files_index_on_deleted_at'

  def up
    add_concurrent_index :packages_composer_cache_files, [:delete_at, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_composer_cache_files, INDEX_NAME
  end
end
