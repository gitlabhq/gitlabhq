class MigrateSharedRunners < ActiveRecord::Migration
  def up
    #all shared runners should remain to be shared
    execute("UPDATE runners SET is_shared = true WHERE id NOT IN (SELECT runner_id FROM runner_projects)");

    Project.update_all(shared_runners_enabled: true)
  end

  def down
  end
end
