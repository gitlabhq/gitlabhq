# frozen_string_literal: true

class AddFkFromPartitionedCiRunnerManagersToPartitionedCiRunners < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def up
    # no-op -- This code caused an incident due to a FK value not being present in the partitioned table
  end

  def down
    # no-op
  end
end
