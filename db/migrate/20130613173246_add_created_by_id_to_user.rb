class AddCreatedByIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :created_by_id, :integer
  end
end
