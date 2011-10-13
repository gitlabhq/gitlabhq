class CreateIssues < ActiveRecord::Migration
  def change
    create_table :issues do |t|
      t.string :title
      t.text :content
      t.integer :assignee_id
      t.integer :author_id
      t.integer :project_id

      t.timestamps
    end
  end
end
