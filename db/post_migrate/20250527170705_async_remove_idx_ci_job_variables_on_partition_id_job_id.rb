# frozen_string_literal: true

class AsyncRemoveIdxCiJobVariablesOnPartitionIdJobId < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  TABLE_NAME = :ci_job_variables
  INDEX_NAME = :index_ci_job_variables_on_partition_id_job_id
  COLUMNS = [:partition_id, :job_id]

  # TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/544929
  def up
    prepare_async_index_removal TABLE_NAME, COLUMNS, name: INDEX_NAME
  end

  def down
    unprepare_async_index TABLE_NAME, COLUMNS, name: INDEX_NAME
  end
end
