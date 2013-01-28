class CreateUserTeams < ActiveRecord::Migration
  def change
    create_table :user_teams do |t|
      t.string :name
      t.string :path
      t.integer :owner_id

      t.timestamps
    end
  end
end
