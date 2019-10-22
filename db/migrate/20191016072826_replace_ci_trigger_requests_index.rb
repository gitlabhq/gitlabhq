# frozen_string_literal: true

class ReplaceCiTriggerRequestsIndex < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_trigger_requests, [:trigger_id, :id], order: { id: :desc }

    remove_concurrent_index :ci_trigger_requests, [:trigger_id]
  end

  def down
    add_concurrent_index :ci_trigger_requests, [:trigger_id]

    remove_concurrent_index :ci_trigger_requests, [:trigger_id, :id], order: { id: :desc }
  end
end
