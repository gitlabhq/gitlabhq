# frozen_string_literal: true

class AddIndexToIssueIdAndCreatedAtOnResourceWeightEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'index_resource_weight_events_on_issue_id_and_created_at'

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :resource_weight_events, [:issue_id, :created_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :resource_weight_events, INDEX_NAME
  end
end
