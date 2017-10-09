# rubocop:disable all
class AddTypeToSnippets < ActiveRecord::Migration[4.2]
  def change
    add_column :snippets, :type, :string
  end
end
