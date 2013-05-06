class AddTypeToKey < ActiveRecord::Migration
  def change
    add_column :keys, :type, :string
  end
end
