# frozen_string_literal: true

class RenameCiPipelineMetadataTitle < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    rename_column_concurrently :ci_pipeline_metadata, :title, :name, batch_column_name: :pipeline_id
  end

  def down
    undo_rename_column_concurrently :ci_pipeline_metadata, :title, :name
  end
end
