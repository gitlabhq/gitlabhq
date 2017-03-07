class AddIndexToCiTriggerRequestsForCommitId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_concurrent_index :ci_trigger_requests, :commit_id
  end
end
