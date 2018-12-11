# rubocop:disable all
class AddProjectViewToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :project_view, :integer, default: 0
  end
end
