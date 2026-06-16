# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      # Caches the Ci::Partition pipelines_id_range -> partition_id mapping in
      # Redis::SharedState so partition-aware pipeline lookups resolve without
      # re-querying ci_partitions on every call. Invalidated by
      # Ci::Partitions::SyncService when partitions switch writes.
      module PartitionCache
        CACHE_KEY = 'ci:pipeline:partition_cache:v1'

        class << self
          def partition_ids_for(pipeline_ids)
            ids = Array.wrap(pipeline_ids).compact
            return [] if ids.empty?

            ranges.filter_map { |partition_id, range| partition_id if covers_any?(range, ids) }
          end

          def ranges
            Gitlab::SafeRequestStore.fetch(CACHE_KEY) { load_ranges }
          end

          def invalidate
            Gitlab::SafeRequestStore.delete(CACHE_KEY)
            Gitlab::Redis::SharedState.with { |redis| redis.del(CACHE_KEY) }
          end

          private

          def covers_any?(range, ids)
            ids.any? { |id| range.cover?(id) }
          end

          def load_ranges
            cached = Gitlab::Redis::SharedState.with { |redis| redis.get(CACHE_KEY) }
            return deserialize(cached) if cached

            load_from_database.tap { |hash| store(hash) }
          end

          # rubocop:disable CodeReuse/ActiveRecord -- targeted query co-located with the cache definition
          def load_from_database
            ::Ci::Partition
              .where.not(pipelines_id_range: nil)
              .pluck(:id, :pipelines_id_range)
              .to_h
          end
          # rubocop:enable CodeReuse/ActiveRecord

          def store(hash)
            tuples = hash.map { |partition_id, range| [partition_id, range.begin, range.end, range.exclude_end?] }
            Gitlab::Redis::SharedState.with { |redis| redis.set(CACHE_KEY, Gitlab::Json.dump(tuples)) }
          end

          def deserialize(payload)
            tuples = Gitlab::Json.safe_parse(payload)
            return {} unless tuples.is_a?(Array)

            tuples.to_h do |partition_id, range_begin, range_end, exclusive|
              [partition_id, Range.new(range_begin, range_end, exclusive)]
            end
          end
        end
      end
    end
  end
end
