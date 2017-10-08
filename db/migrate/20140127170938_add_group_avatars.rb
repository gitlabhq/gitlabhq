# rubocop:disable all
class AddGroupAvatars < ActiveRecord::Migration[4.2]
  def change
    add_column :namespaces, :avatar, :string
  end
end
