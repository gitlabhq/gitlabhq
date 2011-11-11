class RemoveContentFromIssues < ActiveRecord::Migration
  def up
    remove_column :issues, :content
  end

  def down
    add_column :issues, :content, :text
  end
end
