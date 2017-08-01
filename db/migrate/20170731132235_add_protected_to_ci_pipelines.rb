class AddProtectedToCiPipelines < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column(:ci_pipelines, :protected, :boolean)
  end

  def down
    remove_column(:ci_pipelines, :protected)
  end
end
