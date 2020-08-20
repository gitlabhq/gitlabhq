# frozen_string_literal: true

class AddIndexToCiPipelineProjectIdCreatedAt < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipelines, [:project_id, :created_at]
  end

  def down
    remove_concurrent_index :ci_pipelines, [:project_id, :created_at]
  end
end
