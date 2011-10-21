class AddContentTypeToSnippets < ActiveRecord::Migration
  def change
    add_column :snippets, :content_type, :string, :null => false, :default => "txt"
  end
end
