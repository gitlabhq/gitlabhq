# frozen_string_literal: true

class RemoveDependencyListUsageDataFromRedis < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    Gitlab::Redis::SharedState.with { |r| r.del("DEPENDENCY_LIST_USAGE_COUNTER") }
  end

  def down
    # no-op
  end
end
