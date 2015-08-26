class CreateRunnerProjects < ActiveRecord::Migration
  def change
    create_table :runner_projects do |t|
      t.integer :runner_id, null: false
      t.integer :project_id, null: false

      t.timestamps
    end
  end
end
