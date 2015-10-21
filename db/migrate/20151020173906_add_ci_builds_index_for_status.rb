class AddCiBuildsIndexForStatus < ActiveRecord::Migration
  def change
    add_index :ci_builds, [:commit_id, :status, :type]
  end
end
