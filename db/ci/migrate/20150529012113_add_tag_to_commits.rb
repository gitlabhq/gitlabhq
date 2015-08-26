class AddTagToCommits < ActiveRecord::Migration
  def change
    add_column :commits, :tag, :boolean, default: false
  end
end
