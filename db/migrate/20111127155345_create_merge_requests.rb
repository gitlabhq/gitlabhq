class CreateMergeRequests < ActiveRecord::Migration
  def change
    create_table :merge_requests do |t|
      t.string :target_branch, :null => false
      t.string :source_branch, :null => false
      t.integer :project_id, :null => false
      t.integer :author_id
      t.integer :assignee_id
      t.string :title
      t.boolean :closed, :default => false, :null => false

      t.timestamps
    end
  end
end
