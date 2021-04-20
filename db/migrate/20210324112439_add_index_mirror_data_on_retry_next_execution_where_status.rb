# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexMirrorDataOnRetryNextExecutionWhereStatus < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_NAME = 'index_mirror_data_non_scheduled_or_started'

  disable_ddl_transaction!

  def up
    add_concurrent_index :project_mirror_data,
      [:next_execution_timestamp, :retry_count],
      where: "(status)::text <> ALL ('{scheduled,started}'::text[])",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index :project_mirror_data,
      [:next_execution_timestamp, :retry_count],
      where: "(status)::text <> ALL ('{scheduled,started}'::text[])",
      name: INDEX_NAME
  end
end
