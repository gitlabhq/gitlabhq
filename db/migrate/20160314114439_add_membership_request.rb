class AddMembershipRequest < ActiveRecord::Migration
  def change
    add_column :members, :requested, :boolean
  end
end
