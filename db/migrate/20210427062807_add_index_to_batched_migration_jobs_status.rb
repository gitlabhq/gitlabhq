# frozen_string_literal: true

class AddIndexToBatchedMigrationJobsStatus < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_batched_jobs_on_batched_migration_id_and_status'

  def up
    add_concurrent_index :batched_background_migration_jobs, [:batched_background_migration_id, :status], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :batched_background_migration_jobs, INDEX_NAME
  end
end
