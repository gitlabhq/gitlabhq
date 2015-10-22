class FailBuildWithoutNames < ActiveRecord::Migration
  def change
    execute("UPDATE ci_builds SET status='failed' WHERE name IS NULL AND status='pending'")
  end
end
