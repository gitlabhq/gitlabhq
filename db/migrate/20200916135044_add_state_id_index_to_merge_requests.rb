# frozen_string_literal: true

class AddStateIdIndexToMergeRequests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests, [:target_project_id, :iid, :state_id], name: :index_merge_requests_on_target_project_id_and_iid_and_state_id
  end

  def down
    remove_concurrent_index :merge_requests, [:target_project_id, :iid, :state_id], name: :index_merge_requests_on_target_project_id_and_iid_and_state_id
  end
end
