# frozen_string_literal: true

class ValidateFkOnCiSourcesPipelinesSourcePartitionIdAndSourceJobId < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_sources_pipelines
  FK_NAME = :fk_be5624bf37_p
  COLUMNS = [:source_partition_id, :source_job_id]

  def up
    validate_foreign_key(TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    # no-op
  end
end
