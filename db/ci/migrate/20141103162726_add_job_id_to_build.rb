class AddJobIdToBuild < ActiveRecord::Migration
  def change
    add_column :builds, :job_id, :integer
  end
end
