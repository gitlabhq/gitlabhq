# frozen_string_literal: true

class ValidateFkOnCiJobArtifactsPartitionIdAndJobId < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_job_artifacts
  FK_NAME = :fk_rails_c5137cb2c1_p
  COLUMNS = [:partition_id, :job_id]

  def up
    validate_foreign_key(TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    # no-op
  end
end
