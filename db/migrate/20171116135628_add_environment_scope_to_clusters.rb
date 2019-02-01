class AddEnvironmentScopeToClusters < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:clusters, :environment_scope, :string, default: '*')
  end

  def down
    remove_column(:clusters, :environment_scope)
  end
end
