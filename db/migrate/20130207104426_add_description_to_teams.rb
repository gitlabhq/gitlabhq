# rubocop:disable all
class AddDescriptionToTeams < ActiveRecord::Migration[4.2]
  def change
    add_column :user_teams, :description, :string, default: '', null: false
  end
end
