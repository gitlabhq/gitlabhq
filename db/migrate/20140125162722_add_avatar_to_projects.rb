# rubocop:disable all
class AddAvatarToProjects < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :avatar, :string
  end
end
