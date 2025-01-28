# frozen_string_literal: true

module ActiveContext
  class Queues
    def self.queues
      Set.new(@queues ||= [])
    end

    def self.raw_queues
      @raw_queues ||= []
    end

    def self.register!(queue_class)
      key = queue_class.redis_key

      @raw_queues ||= []
      @queues = Set.new(@queues || [])

      return if @queues.include?(key)

      @queues.add(key)

      queue_class.number_of_shards.times do |shard|
        unless @raw_queues.any? { |q| q.instance_of?(queue_class) && q.shard == shard }
          @raw_queues << queue_class.new(shard)
        end
      end
    end

    def self.all_queued_items
      {}.tap do |hash|
        @raw_queues&.each do |raw_queue|
          queue_key = "#{raw_queue.redis_key}:zset"
          references = ActiveContext::Redis.with_redis do |redis|
            redis.zrangebyscore(queue_key, '-inf', '+inf')
          end
          hash[queue_key] = references if references.present?
        end
      end
    end
  end
end
