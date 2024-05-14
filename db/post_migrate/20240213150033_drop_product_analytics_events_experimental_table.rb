# frozen_string_literal: true

class DropProductAnalyticsEventsExperimentalTable < Gitlab::Database::Migration[2.2]
  enable_lock_retries!

  milestone '16.10'

  def up
    drop_table :product_analytics_events_experimental, if_exists: true
  end

  def down
    # no-op
    # Table hasn't been used for many years. No usable production data.
  end
end
