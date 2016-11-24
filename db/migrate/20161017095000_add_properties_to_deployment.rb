class AddPropertiesToDeployment < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :deployments, :on_stop, :string
  end
end
