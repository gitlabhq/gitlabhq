# rubocop:disable all
class AddHideProjectLimitToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :hide_project_limit, :boolean, default: false
  end
end
