class AddInviteDataToMember < ActiveRecord::Migration
  def change
    add_column :members, :created_by_id, :integer
    add_column :members, :invite_email, :string
    add_column :members, :invite_token, :string
    add_column :members, :invite_accepted_at, :datetime

    change_column :members, :user_id, :integer, null: true

    add_index :members, :invite_token, unique: true
  end
end
