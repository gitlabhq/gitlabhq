# frozen_string_literal: true

class AddUniqueIndexForBatchedBackgroundMigrations < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TABLE_NAME = :batched_background_migrations
  INDEX_NAME = 'index_batched_background_migrations_on_unique_configuration'
  REDUNDANT_INDEX_NAME = 'index_batched_migrations_on_job_table_and_column_name'

  def up
    add_concurrent_index TABLE_NAME,
      %i[job_class_name table_name column_name job_arguments],
      unique: true,
      name: INDEX_NAME

    remove_concurrent_index_by_name TABLE_NAME, REDUNDANT_INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME,
      %i[job_class_name table_name column_name],
      name: REDUNDANT_INDEX_NAME

    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
