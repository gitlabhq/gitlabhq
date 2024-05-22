# frozen_string_literal: true

class PersistUsageDataKeysThatShouldNotExpire < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  REDIS_PREFIX = '{event_counters}'

  def up
    overrides = YAML.safe_load(File.read('lib/gitlab/usage_data_counters/total_counter_redis_key_overrides.yml'))

    Gitlab::Redis::SharedState.with do |redis|
      # Update all total counter keys
      redis.scan_each(match: "#{REDIS_PREFIX}*", count: 10_000) do |key|
        redis.persist(key)
      end

      # Update all keys from total_counter_redis_keys_overrides.yml
      overrides.each_value do |legacy_key|
        redis.persist(legacy_key)
      end
    end
  end

  def down
    # no-op
  end
end
