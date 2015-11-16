class FailBuildWithoutNames < ActiveRecord::Migration
  def up
    execute("UPDATE ci_builds SET status='failed' WHERE name IS NULL AND status='pending'")
  end

  def down
  end
end
