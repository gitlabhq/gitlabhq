class AddIncludePrivateContributionsToUsers < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :users, :include_private_contributions, :boolean
  end
end
