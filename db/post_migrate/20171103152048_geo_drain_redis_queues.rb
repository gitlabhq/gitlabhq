# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class GeoDrainRedisQueues < ActiveRecord::Migration
  DOWNTIME = false
  GEO_NAMESPACE = 'geo:gitlab'.freeze

  disable_ddl_transaction!

  def up
    Gitlab::Redis::SharedState.with do |redis|
      # Delete everything from Geo namespace
      matched_keys = redis.scan_each(match: "#{GEO_NAMESPACE}*").to_a
      redis.del(*matched_keys) if matched_keys.any?

      # Delete the keys related to GeoBulkNotifyWorker (which is removed in gitlab-org/gitlab-ee!2644)
      redis.del('resque:gitlab:cron_job:geo_bulk_notify_worker')
      redis.del('resque:gitlab:cron_job:geo_bulk_notify_worker:enqueued')
    end
  end

  def down
    # noop
  end
end
