# frozen_string_literal: true

class TruncateCiFinishedBuildChSyncEventsIfClickHouseNotConfigured < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.4'

  def up
    truncate_tables!('p_ci_finished_build_ch_sync_events') unless ::Gitlab::ClickHouse.configured?
  end

  def down
    # no-op
  end
end
