# frozen_string_literal: true

class DropInt4ColumnsForCiJobArtifacts < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    remove_column :ci_job_artifacts, :id_convert_to_bigint, :integer, null: false, default: 0
    remove_column :ci_job_artifacts, :job_id_convert_to_bigint, :integer, null: false, default: 0
  end
end
