class AddPipelineIidToCiPipelines < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :ci_pipelines, :iid_per_project, :integer
  end

  def down
    remove_column :ci_pipelines, :iid_per_project, :integer
  end
end
