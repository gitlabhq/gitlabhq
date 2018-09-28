class AddPipelineIidToCiPipelines < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :ci_pipelines, :iid, :integer
  end

  def down
    remove_column :ci_pipelines, :iid, :integer
  end
end
