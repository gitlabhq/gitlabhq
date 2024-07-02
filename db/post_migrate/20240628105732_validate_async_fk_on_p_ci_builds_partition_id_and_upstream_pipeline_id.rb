# frozen_string_literal: true

class ValidateAsyncFkOnPCiBuildsPartitionIdAndUpstreamPipelineId < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  TABLE_NAME = :p_ci_builds
  FK_NAME = :fk_87f4cefcda_p
  COLUMNS = [:partition_id, :upstream_pipeline_id]

  def up
    prepare_partitioned_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    unprepare_partitioned_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end
end
