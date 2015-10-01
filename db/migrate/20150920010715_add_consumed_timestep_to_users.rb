class AddConsumedTimestepToUsers < ActiveRecord::Migration
  def change
    add_column :users, :consumed_timestep, :integer
  end
end
