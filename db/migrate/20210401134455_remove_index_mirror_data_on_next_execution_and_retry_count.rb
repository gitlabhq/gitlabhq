# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveIndexMirrorDataOnNextExecutionAndRetryCount < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  INDEX_NAME = 'index_mirror_data_on_next_execution_and_retry_count'

  def up
    remove_concurrent_index(
      :project_mirror_data,
      %i[next_execution_timestamp retry_count],
      name: INDEX_NAME
    )
  end

  def down
    add_concurrent_index(
      :project_mirror_data,
      %i[next_execution_timestamp retry_count],
      name: INDEX_NAME
    )
  end
end
