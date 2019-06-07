# frozen_string_literal: true

# This migration adds temporary indexes to state_id column of issues
# and merge_requests tables. It will be used only to peform the scheduling
# for populating state_id in a post migrate and will be removed after it.
# Check: ScheduleSyncIssuablesStateIdWhereNil.

class AddTemporaryIndexesToStateId < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    %w(issues merge_requests).each do |table|
      add_concurrent_index(
        table,
        'id',
        name: index_name_for(table),
        where: "state_id IS NULL"
      )
    end
  end

  def down
    remove_concurrent_index_by_name(:issues, index_name_for("issues"))
    remove_concurrent_index_by_name(:merge_requests, index_name_for("merge_requests"))
  end

  def index_name_for(table)
    "idx_on_#{table}_where_state_id_is_null"
  end
end
