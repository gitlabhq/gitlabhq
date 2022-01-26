# frozen_string_literal: true

class RemoveCiPipelinesDastSiteProfilesPipelinesCiPipelineIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:dast_site_profiles_pipelines, :ci_pipelines, name: "fk_53849b0ad5")

    with_lock_retries do
      execute('LOCK ci_pipelines, dast_site_profiles_pipelines IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:dast_site_profiles_pipelines, :ci_pipelines, name: "fk_53849b0ad5")
    end
  end

  def down
    add_concurrent_foreign_key(:dast_site_profiles_pipelines, :ci_pipelines, name: "fk_53849b0ad5", column: :ci_pipeline_id, target_column: :id, on_delete: :cascade)
  end
end
