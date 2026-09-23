# frozen_string_literal: true

module Gitlab
  module Ci
    module RedundantPipelines
      # The pipelines on one project and ref that a newer pipeline may auto-cancel,
      # so we can find them without scanning p_ci_pipelines.
      class CandidateCache
        TTL = 24.hours.to_i
        MAX_CLAIMED_PER_CALL = 100
        MAX_SIZE = 1_000

        # The ref is hashed because it is user supplied and unbounded in length.
        def self.for(project_id:, ref:, ttl: TTL)
          redis_key = "ci:redundant_pipelines:#{project_id}:#{Digest::SHA256.hexdigest(ref.to_s)}:candidates"

          new(Store.new(redis_key: redis_key, ttl: ttl))
        end

        def initialize(store)
          @store = store
        end

        def register(key)
          store.register(key, max_size: MAX_SIZE)

          self
        end

        def claim_before(key, limit: MAX_CLAIMED_PER_CALL)
          store.claim_before(key, limit: limit)
        end

        def delete(key)
          store.delete(key)

          self
        end

        def registered?(key)
          store.registered?(key)
        end

        def size
          store.count
        end

        private

        attr_reader :store
      end
    end
  end
end
