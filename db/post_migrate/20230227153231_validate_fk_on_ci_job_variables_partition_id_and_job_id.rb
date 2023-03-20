# frozen_string_literal: true

class ValidateFkOnCiJobVariablesPartitionIdAndJobId < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_job_variables
  FK_NAME = :fk_rails_fbf3b34792_p
  COLUMNS = [:partition_id, :job_id]

  def up
    validate_foreign_key(TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    # no-op
  end
end
