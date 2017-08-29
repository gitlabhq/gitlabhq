class AddIndexToCiPipelinesIid < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:ci_pipelines, [:project_id, :iid])
  end

  def down
    remove_concurrent_index(:ci_pipelines, [:project_id, :iid]) if index_exists?(:ci_pipelines, [:project_id, :iid])
  end
end
