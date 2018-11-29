class RemoveThemeIdFromUsers < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    remove_column :users, :theme_id, :integer
  end
end
