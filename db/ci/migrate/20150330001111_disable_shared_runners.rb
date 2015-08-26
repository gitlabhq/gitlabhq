class DisableSharedRunners < ActiveRecord::Migration
  def up
    execute("UPDATE projects SET shared_runners_enabled = false WHERE id IN (SELECT project_id FROM runner_projects)");
  end

  def down
  end
end
