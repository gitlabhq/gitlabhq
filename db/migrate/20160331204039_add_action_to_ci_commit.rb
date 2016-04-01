class AddActionToCiCommit < ActiveRecord::Migration
  def change
    add_column :ci_commits, :action, :string
  end
end
