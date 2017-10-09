# rubocop:disable all
class AddPriorityToLabel < ActiveRecord::Migration[4.2]
  def change
    add_column :labels, :priority, :integer
    add_index :labels, :priority
  end
end
