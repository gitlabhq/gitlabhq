# frozen_string_literal: true

class IndexBatchedMigrationJobsByMaxValue < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_migration_jobs_on_migration_id_and_max_value'

  def up
    add_concurrent_index :batched_background_migration_jobs, %i(batched_background_migration_id max_value), name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :batched_background_migration_jobs, INDEX_NAME
  end
end
