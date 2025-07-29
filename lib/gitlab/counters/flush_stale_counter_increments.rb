# frozen_string_literal: true

module Gitlab
  module Counters
    class FlushStaleCounterIncrements
      def initialize(collection)
        @collection = collection
        @logger = Gitlab::AppLogger
        @counter_attributes = collection.counter_attributes.keys.map(&:to_sym)
      end

      def execute
        collection_min_id = collection.minimum(:id)
        counter_attributes.each do |attribute|
          logger.info(
            class: self.class,
            attribute: attribute,
            collection_min_id: collection_min_id
          )
          counters = filtered_counters(collection, attribute)
          counters.each_value(&:commit_increment!)
        end
      end

      private

      def filtered_counters(scope, attribute)
        counters = {}
        keys = scope.map { |counter_record| counter_record.counter(attribute).key }

        values = Gitlab::Redis::SharedState.with do |redis|
          if Gitlab::Redis::ClusterUtil.cluster?(redis)
            Gitlab::Redis::ClusterUtil.batch_get(keys, redis)
          else
            redis.mget(*keys)
          end
        end

        values.each_with_index do |value, index|
          next if value.nil?

          key = keys[index]
          counter_record = scope[index]
          counters[key] = counter_record.counter(attribute)
        end
        counters
      end

      attr_reader :collection, :logger, :counter_attributes
    end
  end
end
