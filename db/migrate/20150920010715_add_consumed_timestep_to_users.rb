class AddConsumedTimestepToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :consumed_timestep, :integer
  end
end
