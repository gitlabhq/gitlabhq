# frozen_string_literal: true

class SwitchRecordChangeTrackingToPartitionedCiRunnersTable < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    # no-op -- reverted due to failing check constraint causing broken master
  end

  def down
    # no-op
  end
end
