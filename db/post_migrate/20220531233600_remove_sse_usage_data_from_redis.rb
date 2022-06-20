# frozen_string_literal: true

class RemoveSseUsageDataFromRedis < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    Gitlab::Redis::SharedState.with { |r| r.del("USAGE_STATIC_SITE_EDITOR_VIEWS") }
    Gitlab::Redis::SharedState.with { |r| r.del("USAGE_STATIC_SITE_EDITOR_COMMITS") }
    Gitlab::Redis::SharedState.with { |r| r.del("USAGE_STATIC_SITE_EDITOR_MERGE_REQUESTS") }
  end

  def down
    # no-op
  end
end
