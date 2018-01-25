require 'spec_helper'
require Rails.root.join('ee', 'db', 'post_migrate', '20171103152048_geo_drain_redis_queues')

describe GeoDrainRedisQueues, :clean_gitlab_redis_shared_state do
  subject(:migration) { described_class.new }

  def exists_in_redis?(name)
    Gitlab::Redis::SharedState.with do |redis|
      redis.exists(name)
    end
  end

  def set_in_redis(name, value)
    expect(
      Gitlab::Redis::SharedState.with do |redis|
        redis.set(name, value)
      end
    ).to eq("OK")
  end

  describe '#up' do
    it 'deletes everything in the "geo:gitlab" namespace' do
      set_in_redis('geo:gitlab:foo', 'bar')
      set_in_redis('bar:gitlab:foo', 'bar')

      migration.up

      expect(exists_in_redis?('geo:gitlab:foo')).to be_falsy
      expect(exists_in_redis?('bar:gitlab:foo')).to be_truthy
    end

    it 'deletes "resque:gitlab:cron_job:geo_bulk_notify_worker"' do
      set_in_redis('resque:gitlab:cron_job:geo_bulk_notify_worker', 'bar')
      set_in_redis('resque:gitlab:cron_job:geo_bulk_notify_worker:enqueued', 'bar')
      set_in_redis('resque:gitlab:cron_job:other_worker', 'bar')

      migration.up

      expect(exists_in_redis?('resque:gitlab:cron_job:geo_bulk_notify_worker:enqueued')).to be_falsy
      expect(exists_in_redis?('resque:gitlab:cron_job:geo_bulk_notify_worker')).to be_falsy
      expect(exists_in_redis?('resque:gitlab:cron_job:other_worker')).to be_truthy
    end
  end
end
