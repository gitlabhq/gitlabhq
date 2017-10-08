# rubocop:disable RemoveIndex
class AddIndexToCiTriggerRequestsForCommitId < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_trigger_requests, :commit_id
  end

  def down
    remove_index :ci_trigger_requests, :commit_id if index_exists? :ci_trigger_requests, :commit_id
  end
end
