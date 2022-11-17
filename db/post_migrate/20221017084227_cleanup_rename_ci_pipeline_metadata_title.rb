# frozen_string_literal: true

class CleanupRenameCiPipelineMetadataTitle < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :ci_pipeline_metadata, :title, :name
  end

  def down
    undo_cleanup_concurrent_column_rename :ci_pipeline_metadata, :title, :name, batch_column_name: :pipeline_id
  end
end
