# rubocop:disable all
class AddRepoSizeToDb < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :repository_size, :float, default: 0
  end
end
