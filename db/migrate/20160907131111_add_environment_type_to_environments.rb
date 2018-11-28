class AddEnvironmentTypeToEnvironments < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :environments, :environment_type, :string
  end
end
