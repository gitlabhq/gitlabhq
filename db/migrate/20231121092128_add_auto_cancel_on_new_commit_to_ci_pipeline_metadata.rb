# frozen_string_literal: true

class AddAutoCancelOnNewCommitToCiPipelineMetadata < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.7'

  def change
    add_column :ci_pipeline_metadata, :auto_cancel_on_new_commit, :smallint, default: 0, null: false
  end
end
