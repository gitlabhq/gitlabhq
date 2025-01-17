# frozen_string_literal: true

module ActiveContext
  class Queues
    def self.queues
      Set.new(@queues ||= [])
    end

    def self.raw_queues
      @raw_queues ||= []
    end

    def self.register!(key, shards:)
      raise ArgumentError, "ActiveContext Queue '#{key}' is already registered" if @queues&.include?(key)

      @raw_queues ||= []
      @queues = Set.new(@queues || [])

      @queues.add(key)

      shards.times do |shard|
        @raw_queues << "#{key}:#{shard}"
      end
    end

    def self.all_queued_items
      {}.tap do |hash|
        @raw_queues&.each do |queue_key|
          references = ActiveContext::Redis.with_redis do |redis|
            queue_key = "#{queue_key}:zset"
            redis.zrangebyscore(queue_key, '-inf', '+inf')
          end
          hash[queue_key] = references if references.present?
        end
      end
    end
  end
end
