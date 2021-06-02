# frozen_string_literal: true

class AddForeignKeyForLatestPipelineIdToCiPipelines < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :vulnerability_statistics, :ci_pipelines, column: :latest_pipeline_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :vulnerability_statistics, :ci_pipelines
    end
  end
end
