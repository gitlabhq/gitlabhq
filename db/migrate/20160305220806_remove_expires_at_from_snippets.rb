class RemoveExpiresAtFromSnippets < ActiveRecord::Migration
  def change
    remove_column :snippets, :expires_at, :datetime
  end
end
