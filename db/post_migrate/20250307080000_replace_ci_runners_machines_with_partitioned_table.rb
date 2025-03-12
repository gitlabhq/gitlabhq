# frozen_string_literal: true

class ReplaceCiRunnersMachinesWithPartitionedTable < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.10'

  def up
    replace_with_partitioned_table 'ci_runner_machines'
  end

  def down
    rollback_replace_with_partitioned_table 'ci_runner_machines'
  end
end
