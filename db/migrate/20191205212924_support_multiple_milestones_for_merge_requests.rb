# frozen_string_literal: true

class SupportMultipleMilestonesForMergeRequests < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :merge_request_milestones, id: false do |t|
      t.references :merge_request, foreign_key: { on_delete: :cascade }, index: { unique: true }, null: false
      t.references :milestone, foreign_key: { on_delete: :cascade }, index: true, null: false
    end

    add_index :merge_request_milestones, [:merge_request_id, :milestone_id], name: 'index_mrs_milestones_on_mr_id_and_milestone_id', unique: true
  end
end
