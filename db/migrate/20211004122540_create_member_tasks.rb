# frozen_string_literal: true

class CreateMemberTasks < Gitlab::Database::Migration[1.0]
  def change
    create_table :member_tasks do |t|
      t.references :member, index: true, null: false
      t.references :project, index: true, null: false
      t.timestamps_with_timezone null: false
      t.integer :tasks, limit: 2, array: true, null: false, default: []
      t.index [:member_id, :project_id], unique: true
    end
  end
end
