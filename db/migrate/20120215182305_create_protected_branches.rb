class CreateProtectedBranches < ActiveRecord::Migration
  def change
    create_table :protected_branches do |t|
      t.integer :project_id, :null => false
      t.string :name, :null => false

      t.timestamps
    end
  end
end
