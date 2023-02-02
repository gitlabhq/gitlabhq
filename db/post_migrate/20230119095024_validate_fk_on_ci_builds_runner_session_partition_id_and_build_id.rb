# frozen_string_literal: true

class ValidateFkOnCiBuildsRunnerSessionPartitionIdAndBuildId < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_builds_runner_session
  FK_NAME = :fk_rails_70707857d3_p
  COLUMNS = [:partition_id, :build_id]

  def up
    validate_foreign_key(TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    # no-op
  end
end
