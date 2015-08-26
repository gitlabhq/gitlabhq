class AddRunnerIdToBuild < ActiveRecord::Migration
  def change
    add_column :builds, :runner_id, :integer
  end
end
