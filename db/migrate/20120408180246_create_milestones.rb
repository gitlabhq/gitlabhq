class CreateMilestones < ActiveRecord::Migration
  def change
    create_table :milestones do |t|
      t.string :title, :null => false
      t.integer :project_id, :null => false
      t.text :description
      t.date :due_date
      t.boolean :closed, :default => false, :null => false
      t.timestamps
    end
  end
end
