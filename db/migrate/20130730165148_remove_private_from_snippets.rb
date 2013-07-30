class RemovePrivateFromSnippets < ActiveRecord::Migration
  def up
    remove_column :snippets, :private
  end

  def down
    add_column :snippets, :private, :boolean, null: false, default: true
  end
end
