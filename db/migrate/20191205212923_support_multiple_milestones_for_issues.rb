# frozen_string_literal: true

class SupportMultipleMilestonesForIssues < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :issue_milestones, id: false do |t|
      t.references :issue, foreign_key: { on_delete: :cascade }, index: { unique: true }, null: false
      t.references :milestone, foreign_key: { on_delete: :cascade }, index: true, null: false
    end

    add_index :issue_milestones, [:issue_id, :milestone_id], unique: true
  end
end
