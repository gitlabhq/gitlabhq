class AddExpiresAtToSnippets < ActiveRecord::Migration
  def change
    add_column :snippets, :expires_at, :datetime
  end
end
