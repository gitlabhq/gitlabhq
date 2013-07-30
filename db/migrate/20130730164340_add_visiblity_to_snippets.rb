class AddVisiblityToSnippets < ActiveRecord::Migration
  def change
    add_column :snippets, :visibility, :string, null: false, default :private
  end
end
