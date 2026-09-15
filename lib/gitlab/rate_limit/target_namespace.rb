# frozen_string_literal: true

module Gitlab
  module RateLimit
    module TargetNamespace
      CACHE_EXPIRATION = 1.hour
      NEGATIVE_CACHE_EXPIRATION = 10.minutes
      UNRESOLVED = ''

      # A hot route can be behind hundreds of concurrent requests, and without this they
      # would all miss together on expiry and run the same lookup.
      RACE_CONDITION_TTL = 10.seconds

      # Sized from routes.path, a varchar(255), so a longer route can never match. Applied
      # to numeric identifiers too, where it caps the Redis key rather than the lookup.
      MAX_TARGET_BYTES = 255

      class << self
        def id_for_path(path)
          resolve(TargetKey.for(path))
        end

        def id_for_project(project_id)
          resolve(Target.new(type: :project, identifier: project_id.to_s))
        end

        def id_for_group(group_id)
          resolve(Target.new(type: :group, identifier: group_id.to_s))
        end

        private

        def resolve(target)
          return unless target
          # Rejected before the cache read so a bad identifier cannot mint a Redis key
          # either.
          return if target.identifier.empty? || target.identifier.bytesize > MAX_TARGET_BYTES

          cached("namespace_id:#{target.cache_key}") { target.root_id }
        end

        # skip_nil leaves an unresolved lookup to the shorter expiry below, and UNRESOLVED
        # is truthy so a cached miss short-circuits fetch instead of re-running the block.
        def cached(key)
          ::Gitlab::SafeRequestStore.fetch(key) do
            id = ::Rails.cache.fetch(
              key, expires_in: CACHE_EXPIRATION, race_condition_ttl: RACE_CONDITION_TTL, skip_nil: true
            ) { yield&.to_s }
            next id.presence if id

            ::Rails.cache.write(key, UNRESOLVED, expires_in: NEGATIVE_CACHE_EXPIRATION)
            nil
          end
        end
      end
    end
  end
end
