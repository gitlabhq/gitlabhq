class FailBuildWithEmptyName < ActiveRecord::Migration
  def change
    execute("UPDATE ci_builds SET status='failed' WHERE (name IS NULL OR name='') AND status='pending'")
  end
end
