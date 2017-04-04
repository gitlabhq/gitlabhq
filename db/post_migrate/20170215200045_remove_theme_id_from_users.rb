class RemoveThemeIdFromUsers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    remove_column :users, :theme_id, :integer
  end
end
