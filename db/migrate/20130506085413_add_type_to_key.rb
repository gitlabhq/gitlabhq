# rubocop:disable all
class AddTypeToKey < ActiveRecord::Migration[4.2]
  def change
    add_column :keys, :type, :string
  end
end
