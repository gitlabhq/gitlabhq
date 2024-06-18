# frozen_string_literal: true

class DropDefaultValueForPCiBuildsAutoCanceledByPartitionId < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    change_column_default(:p_ci_builds, :auto_canceled_by_partition_id, nil)
    change_column_null(:p_ci_builds, :auto_canceled_by_partition_id, true)
  end

  def down
    change_column_default(:p_ci_builds, :auto_canceled_by_partition_id, 100)
    change_column_null(:p_ci_builds, :auto_canceled_by_partition_id, false)
  end
end
