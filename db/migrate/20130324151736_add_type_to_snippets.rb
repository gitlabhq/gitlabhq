class AddTypeToSnippets < ActiveRecord::Migration
  def change
    add_column :snippets, :type, :string
  end
end
