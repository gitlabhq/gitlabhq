# rubocop:disable Migration/Datetime
class AddRequestedAtToMembers < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :requested_at, :datetime
  end
end
