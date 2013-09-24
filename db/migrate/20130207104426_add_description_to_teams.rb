class AddDescriptionToTeams < ActiveRecord::Migration
  def change
    add_column :user_teams, :description, :string, default: '', null: false
  end
end
