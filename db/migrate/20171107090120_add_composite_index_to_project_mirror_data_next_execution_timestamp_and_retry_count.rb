# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddCompositeIndexToProjectMirrorDataNextExecutionTimestampAndRetryCount < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_mirror_data_on_next_execution_and_retry_count'

  disable_ddl_transaction!

  def up
    add_concurrent_index(:project_mirror_data, [:next_execution_timestamp, :retry_count], name: INDEX_NAME)
  end

  def down
    if index_exists?(:project_mirror_data, [:next_execution_timestamp, :retry_count], name: INDEX_NAME)
      remove_concurrent_index(:project_mirror_data, [:next_execution_timestamp, :retry_count], name: INDEX_NAME)
    end
  end
end
