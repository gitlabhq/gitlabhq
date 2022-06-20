# frozen_string_literal: true

class IndexBatchedMigrationsOnGitlabSchemaAndConfiguration < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  TABLE_NAME = :batched_background_migrations
  INDEX_NAME = 'index_batched_migrations_on_gl_schema_and_unique_configuration'

  def up
    add_concurrent_index TABLE_NAME,
      %i[gitlab_schema job_class_name table_name column_name job_arguments],
      unique: true,
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
