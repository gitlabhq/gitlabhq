class AddGroupAvatars < ActiveRecord::Migration
  def change
    add_column :namespaces, :avatar, :string
  end
end
