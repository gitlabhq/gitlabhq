class AddDurationToCiCommit < ActiveRecord::Migration
  def change
    add_column :ci_commits, :duration, :integer
  end
end
