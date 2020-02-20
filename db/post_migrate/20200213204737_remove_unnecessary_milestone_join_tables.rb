# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveUnnecessaryMilestoneJoinTables < ActiveRecord::Migration[6.0]
  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    drop_table :issue_milestones
    drop_table :merge_request_milestones
  end

  def down
    create_table :issue_milestones, id: false do |t|
      t.references :issue, foreign_key: { on_delete: :cascade }, index: { unique: true }, null: false
      t.references :milestone, foreign_key: { on_delete: :cascade }, index: true, null: false
    end

    add_index :issue_milestones, [:issue_id, :milestone_id], unique: true

    create_table :merge_request_milestones, id: false do |t|
      t.references :merge_request, foreign_key: { on_delete: :cascade }, index: { unique: true }, null: false
      t.references :milestone, foreign_key: { on_delete: :cascade }, index: true, null: false
    end

    add_index :merge_request_milestones, [:merge_request_id, :milestone_id], name: 'index_mrs_milestones_on_mr_id_and_milestone_id', unique: true
  end
end
