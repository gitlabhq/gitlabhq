# rubocop:disable all
class AddIndexToSnippet < ActiveRecord::Migration[4.2]
  def change
    add_index :snippets, :updated_at
  end
end
