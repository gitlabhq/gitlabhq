class AddDbIndex < ActiveRecord::Migration
  def change
    add_index :builds, :runner_id
    add_index :runner_projects, :runner_id
    add_index :runner_projects, :project_id
  end
end
