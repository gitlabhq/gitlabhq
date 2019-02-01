class AddLastActivityOnToUsers < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :users, :last_activity_on, :date
  end
end
