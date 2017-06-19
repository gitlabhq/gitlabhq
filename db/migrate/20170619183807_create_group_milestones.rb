class CreateGroupMilestones < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :group_milestones do |t|
      t.integer :group_id
      t.string :title
      t.text :description
      t.date :start_date
      t.date :due_date
      t.string :state
      t.string :title_html
      t.string :description_html
      t.integer :cached_markdown_version, limit: 4
    end

    add_column :issues, :group_milestone_id, :integer
    add_column :merge_requests, :group_milestone_id, :integer

    add_foreign_key :group_milestones, :namespaces, column: :group_id, null: false # rubocop: disable Migration/AddConcurrentForeignKey
    add_index :group_milestones, :group_id
  end
end
