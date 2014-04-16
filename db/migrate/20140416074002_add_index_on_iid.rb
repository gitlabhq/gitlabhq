class AddIndexOnIid < ActiveRecord::Migration
  def change
    add_index :issues, [:project_id, :iid], unique: true
    add_index :merge_requests, [:target_project_id, :iid], unique: true
    add_index :milestones, [:project_id, :iid], unique: true
  end
end
