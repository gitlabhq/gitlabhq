# frozen_string_literal: true

module Namespaces
  class EnableDescendantsCacheCronWorker
    include ApplicationWorker
    # rubocop:disable Scalability/CronWorkerContext -- This worker does not perform work scoped to a context
    include CronjobQueue

    GROUP_BATCH_SIZE = 5000
    NAMESPACE_BATCH_SIZE = 500
    PERSIST_SLICE_SIZE = 100
    # Covers the top 3000 namespaces on .com
    CACHE_THRESHOLD = 700
    CURSOR_KEY = 'enable_namespace_descendants_cron_worker'

    MAX_RUNTIME = 45.seconds

    data_consistency :sticky

    # rubocop:enable Scalability/CronWorkerContext

    feature_category :groups_and_projects
    idempotent!

    # rubocop: disable CodeReuse/ActiveRecord -- Batching over groups.
    def perform
      # rubocop: disable Gitlab/FeatureFlagWithoutActor -- This is a global worker.
      return if Feature.disabled?(:periodical_namespace_descendants_cache_worker)

      # rubocop: enable Gitlab/FeatureFlagWithoutActor

      limiter = Gitlab::Metrics::RuntimeLimiter.new(MAX_RUNTIME)
      ids_to_cache = Set.new
      last_id = get_last_id

      # 1. Iterate over groups.
      # 2. For each group, start counting the descendants.
      # 3. When CACHE_THRESHOLD count is reached, stop the counting.
      Group.where('id > ?', last_id || 0).each_batch(of: GROUP_BATCH_SIZE) do |relation|
        relation.select(:id).each do |group|
          cursor = { current_id: group.id, depth: [group.id] }
          iterator = Gitlab::Database::NamespaceEachBatch.new(namespace_class: Namespace, cursor: cursor)
          count = 0
          iterator.each_batch(of: NAMESPACE_BATCH_SIZE) do |ids|
            count += ids.size

            break if count >= CACHE_THRESHOLD || limiter.over_time?
          end

          ids_to_cache << group.id if count >= CACHE_THRESHOLD

          break if limiter.was_over_time?

          last_id = group.id
        end
        break if limiter.was_over_time?
      end

      last_id = nil unless limiter.was_over_time?

      persist(ids_to_cache)
      set_last_id(last_id)

      log_extra_metadata_on_done(:result,
        { over_time: limiter.was_over_time?, last_id: last_id, cache_count: ids_to_cache.size })
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def persist(ids_to_cache)
      ids_to_cache.each_slice(PERSIST_SLICE_SIZE) do |slice|
        Namespaces::Descendants.upsert_all(slice.map { |id| { namespace_id: id } })
      end
    end

    def get_last_id
      value = Gitlab::Redis::SharedState.with { |redis| redis.get(CURSOR_KEY) }
      return if value.nil?

      Integer(value)
    end

    def set_last_id(last_id)
      if last_id.nil?
        Gitlab::Redis::SharedState.with { |redis| redis.del(CURSOR_KEY) }
      else
        Gitlab::Redis::SharedState.with { |redis| redis.set(CURSOR_KEY, last_id, ex: 1.day) }
      end
    end
  end
end
