class AddLastActivityOnToUsers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :users, :last_activity_on, :date
  end
end
