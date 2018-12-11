# rubocop:disable all
class RemoveExpiresAtFromSnippets < ActiveRecord::Migration[4.2]
  def change
    remove_column :snippets, :expires_at, :datetime
  end
end
