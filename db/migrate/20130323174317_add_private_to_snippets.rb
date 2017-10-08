# rubocop:disable all
class AddPrivateToSnippets < ActiveRecord::Migration[4.2]
  def change
    add_column :snippets, :private, :boolean, null: false, default: true
  end
end
