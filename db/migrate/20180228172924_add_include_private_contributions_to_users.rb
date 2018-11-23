class AddIncludePrivateContributionsToUsers < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    add_column :users, :include_private_contributions, :boolean
  end
end
