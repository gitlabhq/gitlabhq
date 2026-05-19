# frozen_string_literal: true

module ActiveContext
  class Queues
    def self.queues
      register_all_queues!

      Set.new(@queue_classes_map.keys)
    end

    def self.raw_queues
      register_all_queues!
      build_raw_queues
    end

    def self.configured_queue_classes
      ActiveContext::Config.queue_classes
    end

    def self.build_raw_queues
      @queue_classes_map.each_value.flat_map do |queue_class|
        (0...queue_class.number_of_shards).map { |shard| queue_class.new(shard) }
      end
    end

    def self.register_all_queues!
      return if @queues_registered

      configured_queue_classes.each do |q|
        register!(q)
      end

      register!(RetryQueue)

      @queues_registered = true
    end

    def self.register!(queue_class)
      key = queue_class.redis_key

      @queue_classes_map ||= {}

      return if @queue_classes_map.key?(key)

      @queue_classes_map[key] = queue_class
    end

    def self.all_queued_items
      {}.tap do |hash|
        raw_queues&.each do |raw_queue|
          queue_key = "#{raw_queue.redis_key}:zset"
          references = ActiveContext::Redis.with_redis do |redis|
            redis.zrangebyscore(queue_key, '-inf', '+inf')
          end
          hash[queue_key] = references if references.present?
        end
      end
    end

    def self.queue_counts
      queue_counts = []

      raw_queues&.each do |raw_queue|
        queue_key = "#{raw_queue.redis_key}:zset"
        count = ActiveContext::Redis.with_redis do |redis|
          redis.zcard(queue_key)
        end

        queue_counts << { queue_name: raw_queue.class.name, shard: raw_queue.shard, count: count }
      end

      queue_counts
    end
  end
end
