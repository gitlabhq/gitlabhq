# frozen_string_literal: true

class AddAsyncTmpIndexJobArtifactsIdAndExpireAt < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_index_ci_job_artifacts_on_id_expire_at_file_type_trace'

  EXPIRE_AT_ON_22_MIDNIGHT_IN_TIMEZONE_OR_TRACE = <<~SQL
    (EXTRACT(day FROM timezone('UTC', expire_at)) IN (21, 22, 23)
    AND EXTRACT(minute FROM timezone('UTC', expire_at)) IN (0, 30, 45)
    AND EXTRACT(second FROM timezone('UTC', expire_at)) = 0)
    OR file_type = 3
  SQL

  def up
    prepare_async_index :ci_job_artifacts, :id,
                         where: EXPIRE_AT_ON_22_MIDNIGHT_IN_TIMEZONE_OR_TRACE, name: INDEX_NAME
  end

  def down
    unprepare_async_index :ci_job_artifacts, INDEX_NAME
  end
end
