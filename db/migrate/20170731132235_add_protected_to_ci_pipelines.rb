class AddProtectedToCiPipelines < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:ci_pipelines, :protected, :boolean, default: false)
  end

  def down
    remove_column(:ci_pipelines, :protected)
  end
end
