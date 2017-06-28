class AddStateToEnvironment < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default(:environments, :state, :string, default: :available)
  end

  def down
    remove_column(:environments, :state)
  end
end
