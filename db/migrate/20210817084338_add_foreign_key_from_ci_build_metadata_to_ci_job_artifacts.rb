# frozen_string_literal: true

class AddForeignKeyFromCiBuildMetadataToCiJobArtifacts < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_build_trace_metadata,
      :ci_job_artifacts,
      column: :trace_artifact_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :ci_build_trace_metadata, column: :trace_artifact_id
    end
  end
end
