class AddKeyTitleToKey < ActiveRecord::Migration
  def change
    add_column :keys, :key, :text
    add_column :keys, :title, :string
    remove_column :keys, :project_id
  end
end
