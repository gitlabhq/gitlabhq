# frozen_string_literal: true

class DropSyncTriggersFromWebHookCallsPlanLimits < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    drop_trigger('trigger_c0776354152a', 'plan_limits')
    drop_trigger('trigger_d0c336b01d00', 'plan_limits')
    drop_trigger('trigger_e19c4cf656dc', 'plan_limits')
  end

  def down
    # noop
  end
end
