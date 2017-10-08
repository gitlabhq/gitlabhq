# rubocop:disable all
class AddCreatedByIdToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :created_by_id, :integer
  end
end
