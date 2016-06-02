class AddTypeToNotes < ActiveRecord::Migration
  def change
    add_column :notes, :type, :string
  end
end
