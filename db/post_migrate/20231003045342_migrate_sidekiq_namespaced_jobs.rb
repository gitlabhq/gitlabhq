# frozen_string_literal: true

class MigrateSidekiqNamespacedJobs < Gitlab::Database::Migration[2.1]
  BATCH_SIZE = 1000
  SORTED_SET_NAMES = %w[schedule retry dead]

  def up
    SORTED_SET_NAMES.each do |set_name|
      sorted_set_migrate("resque:gitlab:#{set_name}", set_name)
    end

    Sidekiq::Queue.all.each do |queue|
      name = queue.name
      sidekiq_queue_migrate("resque:gitlab:queue:#{name}", to: "queue:#{name}")
    end
  end

  def down
    SORTED_SET_NAMES.each do |set_name|
      sorted_set_migrate(set_name, "resque:gitlab:#{set_name}")
    end

    Sidekiq::Queue.all.each do |queue|
      name = queue.name
      sidekiq_queue_migrate("queue:#{name}", to: "resque:gitlab:queue:#{name}")
    end
  end

  private

  def sidekiq_queue_migrate(queue_from, to:)
    Gitlab::Redis::Queues.with do |conn| # rubocop:disable Cop/RedisQueueUsage
      conn.rpoplpush(queue_from, to) while conn.llen(queue_from) > 0
    end
  end

  def sorted_set_migrate(from, to)
    cursor = '0'

    loop do
      result = []

      Gitlab::Redis::Queues.with do |redis| # rubocop:disable Cop/RedisQueueUsage
        cursor, result = redis.zscan(from, cursor, count: BATCH_SIZE)

        next if result.empty?

        redis.multi do |multi|
          multi.zadd(to, result.map { |k, v| [v, k] })
          multi.zrem(from, result.map { |k, _v| k })
        end
      end

      sleep(0.01)

      break if cursor == '0'
    end
  end
end
