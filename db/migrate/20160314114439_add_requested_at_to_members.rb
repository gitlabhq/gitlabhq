class AddRequestedAtToMembers < ActiveRecord::Migration
  def change
    add_column :members, :requested_at, :datetime
  end
end
