# rubocop:disable all
class AddPrivateToSnippets < ActiveRecord::Migration
  def change
    add_column :snippets, :private, :boolean, null: false, default: true
  end
end
