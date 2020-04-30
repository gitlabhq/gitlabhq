# frozen_string_literal: true

class AddForeignKeyFromProjectsToMetricsUsersStarredDashboars < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :metrics_users_starred_dashboards, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do # rubocop:disable Migration/WithLockRetriesWithoutDdlTransaction
      remove_foreign_key_if_exists :metrics_users_starred_dashboards, column: :project_id
    end
  end
end
