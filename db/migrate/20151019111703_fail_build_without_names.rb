class FailBuildWithoutNames < ActiveRecord::Migration[4.2]
  def up
    execute("UPDATE ci_builds SET status='failed' WHERE name IS NULL AND status='pending'")
  end

  def down
  end
end
