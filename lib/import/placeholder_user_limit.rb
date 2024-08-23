# frozen_string_literal: true

module Import
  class PlaceholderUserLimit
    UNLIMITED = 0
    LIMIT_TIER_1 = :import_placeholder_user_limit_tier_1
    EXCEEDANCE_CACHE_TTL = 1.minute
    LIMIT_CACHE_TTL = 1.hour

    def initialize(namespace:)
      @root_namespace = namespace.root_ancestor
    end

    def exceeded?
      return false if unlimited?

      cache.read(cache_key).present? || calculate_has_exceeded.tap do |has_exceeded|
        if has_exceeded
          log_limit_exceeded

          # Cache when the limit has been exceeded.
          # As placeholder users can be deleted during contribution reassignment, a namespace
          # can go below their limit again so we only cache for a short period of time.
          cache.write(cache_key, true, timeout: EXCEEDANCE_CACHE_TTL)
        end
      end
    end

    private

    attr_reader :root_namespace

    def calculate_has_exceeded
      count = ::Import::SourceUser.namespace_placeholder_user_count(root_namespace, limit: limit)
      return false unless count > 0

      count >= limit
    end

    def limit
      cached_limit = cache.read_integer(limit_cache_key)
      return cached_limit unless cached_limit.nil?

      calculate_limit.tap do |limit|
        # Cache to avoid looking up the plan and seat count again (in the EE module).
        # As these details rarely change, we can cache for a longer period.
        cache.write(limit_cache_key, limit, timeout: LIMIT_CACHE_TTL)
      end
    end

    def calculate_limit
      plan.actual_limits.limit_for(limit_name) || UNLIMITED
    end

    def unlimited?
      limit == UNLIMITED
    end

    # Overridden in EE to return limit names based on licensed seats
    def limit_name
      LIMIT_TIER_1
    end

    def plan
      @plan ||= root_namespace.actual_plan
    end

    def cache
      Gitlab::Cache::Import::Caching
    end

    def cache_key
      "import_placeholder_user_limit:exceeded:#{root_namespace.id}"
    end

    def limit_cache_key
      "import_placeholder_user_limit:limit:#{root_namespace.id}"
    end

    def log_limit_exceeded
      Gitlab::ApplicationContext.with_context(namespace: root_namespace) do
        Import::Framework::Logger.info(
          message: 'Placeholder user limit exceeded for namespace',
          limit: limit
        )
      end
    end
  end
end

Import::PlaceholderUserLimit.prepend_mod
