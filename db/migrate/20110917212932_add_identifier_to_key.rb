class AddIdentifierToKey < ActiveRecord::Migration
  def change
    add_column :keys, :identifier, :string
  end
end
