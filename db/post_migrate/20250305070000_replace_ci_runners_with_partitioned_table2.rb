# frozen_string_literal: true

class ReplaceCiRunnersWithPartitionedTable2 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.10'

  def up
    return if rolled_back_migration_already_ran?

    replace_with_partitioned_table 'ci_runners'
  end

  def down
    rollback_replace_with_partitioned_table 'ci_runners'
  end

  private

  def rolled_back_migration_already_ran?
    connection.table_exists?('ci_runners_archived')
  end
end
