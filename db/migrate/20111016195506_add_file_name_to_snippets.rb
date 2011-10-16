class AddFileNameToSnippets < ActiveRecord::Migration
  def change
    add_column :snippets, :file_name, :string
    remove_column :snippets, :content_type
  end
end
