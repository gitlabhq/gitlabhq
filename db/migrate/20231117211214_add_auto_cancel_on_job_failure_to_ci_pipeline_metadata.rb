# frozen_string_literal: true

class AddAutoCancelOnJobFailureToCiPipelineMetadata < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  enable_lock_retries!

  def change
    add_column :ci_pipeline_metadata, :auto_cancel_on_job_failure, :smallint, default: 0, null: false
  end
end
