# rubocop:disable all
class AddPriorityToLabel < ActiveRecord::Migration
  def change
    add_column :labels, :priority, :integer
    add_index :labels, :priority
  end
end
