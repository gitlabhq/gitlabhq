# frozen_string_literal: true

class AddIndexForComplianceMergedMergeRequestToEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_events_on_project_id_and_id_desc_on_merged_action'

  disable_ddl_transaction!

  def up
    add_concurrent_index :events, [:project_id, :id],
      order: { id: :desc },
      where: "action = 7", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :events, INDEX_NAME
  end
end
