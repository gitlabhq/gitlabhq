class AddProtectedToCiVariables < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:ci_variables, :protected, :boolean, default: false)
  end

  def down
    remove_column(:ci_variables, :protected)
  end
end
