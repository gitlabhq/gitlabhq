class AddCommitsCountToProject < ActiveRecord::Migration
  def change
    add_column :projects, :commit_count, :integer, default: 0
  end
end
