# frozen_string_literal: true

class DropInt4ColumnForCiSourcesPipelines < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    remove_column :ci_sources_pipelines, :source_job_id_convert_to_bigint, :integer
  end
end
