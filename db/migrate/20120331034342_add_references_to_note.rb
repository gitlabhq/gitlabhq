class AddReferencesToNote < ActiveRecord::Migration
  def up
    add_column :notes, :reference_id, :string
    add_column :notes, :reference_type, :string
  end

  def down
  end
end