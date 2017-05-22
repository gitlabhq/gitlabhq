class AddSchemaVersionToCiPipelines < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_pipelines, :schema_version, :integer
  end
end
