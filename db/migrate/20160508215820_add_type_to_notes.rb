class AddTypeToNotes < ActiveRecord::Migration[4.2]
  def change
    add_column :notes, :type, :string
  end
end
