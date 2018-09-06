# frozen_string_literal: true

class AddProjectConfigSourceStatusIndexToPipeline < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipelines, [:project_id, :status, :config_source]
  end

  def down
    remove_concurrent_index :ci_pipelines, [:project_id, :status, :config_source]
  end
end
