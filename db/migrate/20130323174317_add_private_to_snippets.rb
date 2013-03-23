class AddPrivateToSnippets < ActiveRecord::Migration
  def change
    add_column :snippets, :private, :boolean
  end
end
