# frozen_string_literal: true

class AddCiPipelineIdFkToDastSiteProfilesPipelines < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :dast_site_profiles_pipelines, :ci_pipelines, column: :ci_pipeline_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :dast_site_profiles_pipelines, column: :ci_pipeline_id
    end
  end
end
