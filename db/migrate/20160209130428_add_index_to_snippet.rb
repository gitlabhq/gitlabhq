class AddIndexToSnippet < ActiveRecord::Migration
  def change
    add_index :snippets, :updated_at
  end
end
