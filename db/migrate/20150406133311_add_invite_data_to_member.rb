class AddInviteDataToMember < ActiveRecord::Migration
  def up
    add_column :members, :created_by_id, :integer
    add_column :members, :invite_email, :string
    add_column :members, :invite_token, :string
    add_column :members, :invite_accepted_at, :datetime

    change_column :members, :user_id, :integer, null: true

    add_index :members, :invite_token, unique: true
  end

  def down
    remove_index :members, :invite_token

    change_column :members, :user_id, :integer, null: false

    remove_column :members, :invite_accepted_at
    remove_column :members, :invite_token
    remove_column :members, :invite_email
    remove_column :members, :created_by_id
  end
end
