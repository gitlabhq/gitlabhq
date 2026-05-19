# frozen_string_literal: true

module Gitlab
  module ApplicationRateLimiter
    # Routes a subset of ApplicationRateLimiter checks through Labkit::RateLimit::Limiter.
    #
    # Behaviour is gated by two wip feature flags. The flag basis is either
    # the key itself (cohort 1, no `flag_scope:`) or a cohort-wide symbol
    # (`flag_scope: :cohort_N`); see SupportedRateLimits for the per-entry
    # convention.
    #
    #   - rate_limiter_use_labkit_<basis>          : run the labkit path alongside legacy
    #   - rate_limiter_use_labkit_<basis>_enforce  : let labkit's decision win over legacy
    #
    # The two flags produce three states:
    #
    #   use_labkit off / enforce off : only the legacy path runs.
    #   use_labkit on  / enforce off : both paths run; the legacy decision is
    #                                  returned. The shadow counter records
    #                                  whether the two paths agree.
    #   use_labkit on  / enforce on  : only the labkit path runs; its decision
    #                                  is returned.
    #
    # The legacy and labkit Redis key shapes are intentionally disjoint
    # ("application_rate_limiter:..." vs "labkit:rl:...") so both counters can
    # increment independently without interfering with each other.
    module LabkitAdapter
      # Window-boundary skew between labkit's TTL and legacy's divmod-based
      # period_key produces sub-second disagreements that are not bugs. The
      # shadow counter still records these events but tags them with
      # `boundary: true` so dashboards can filter them out of "should we
      # flip enforce?" queries while keeping the data observable.
      BOUNDARY_NOISE_SECONDS = 1

      class << self
        # Feature.current_request as the actor gives a global on/off semantic for
        # request-bound callers. For non-request callers (e.g. pipelines_create
        # invoked from a Sidekiq worker), Feature.current_request resolves to a
        # fresh per-call UUID, so percentage rollouts behave non-deterministically
        # from non-request paths. Operate these flags as fully on or fully off.

        def shadow_or_enforce?(key, threshold_override:, interval_override:)
          return false unless SupportedRateLimits.all.key?(key)

          if !threshold_override.nil? || !interval_override.nil?
            record_override(key, threshold_override, interval_override)
            return false
          end

          # rubocop:disable Gitlab/FeatureFlagKeyDynamic -- flag bases enumerated in SupportedRateLimits.all with matching YAMLs in config/feature_flags/wip/
          Feature.enabled?(:"rate_limiter_use_labkit_#{flag_basis(key)}", Feature.current_request, type: :wip)
          # rubocop:enable Gitlab/FeatureFlagKeyDynamic
        end

        # Whether labkit's decision should win over the legacy decision.
        def enforce?(key)
          return false unless SupportedRateLimits.all.key?(key)

          # rubocop:disable Gitlab/FeatureFlagKeyDynamic -- flag bases enumerated in SupportedRateLimits.all with matching YAMLs in config/feature_flags/wip/
          Feature.enabled?(:"rate_limiter_use_labkit_#{flag_basis(key)}_enforce", Feature.current_request, type: :wip)
          # rubocop:enable Gitlab/FeatureFlagKeyDynamic
        end

        # Always increments the labkit counter and returns labkit's boolean
        # decision (whether the request should be blocked, ignoring whether
        # enforcement is on).
        #
        # @return [Boolean] labkit's decision (exceeded?)
        def run!(key, scope:)
          spec = SupportedRateLimits.all.fetch(key)
          rule = build_rule(key, spec)
          result = build_limiter(spec, rule).check(identifier_for(rule, scope))

          return false if result.error?

          result.exceeded?
        end

        # Reads the labkit counter without incrementing and returns labkit's
        # boolean decision. Mirrors {#run!} for callers that route through
        # ApplicationRateLimiter#peek (cohort 3). The labkit Redis key shape
        # is identical to {#run!} so a peek observes the same counter that
        # a paired non-peek call site increments.
        #
        # @return [Boolean] labkit's decision (exceeded?)
        def run_peek!(key, scope:)
          spec = SupportedRateLimits.all.fetch(key)
          rule = build_rule(key, spec)
          result = build_limiter(spec, rule).peek(identifier_for(rule, scope))

          return false if result.error?

          result.exceeded?
        end

        # Compares labkit's decision against the legacy path's decision and
        # increments a Prometheus counter labelled by agreement and by whether
        # the check landed within BOUNDARY_NOISE_SECONDS of a window edge.
        # Boundary-edge events are tagged rather than dropped so dashboards
        # can filter them out of go/no-go queries without losing the
        # underlying signal (e.g. "is labkit systematically blocking more
        # than legacy at the edges?").
        def record_divergence(key, labkit_decision, legacy_decision)
          agreement = labkit_decision == legacy_decision ? :match : :diverge
          shadow_counter.increment(key: key, agreement: agreement, boundary: window_boundary?(key))
        end

        private

        # Resolves the shadow/enforce flag-name basis for a key. Cohort 1
        # entries (no flag_scope) use the key itself; cohort-wide entries
        # (`flag_scope: :cohort_N`) use the scope symbol so every entry in
        # the cohort shares one flag pair.
        def flag_basis(key)
          SupportedRateLimits.all.fetch(key)[:flag_scope] || key
        end

        def build_limiter(spec, rule)
          ::Labkit::RateLimit::Limiter.new(
            name: spec[:limiter_name],
            rules: [rule],
            redis: ::Gitlab::Redis::RateLimiting,
            logger: ::Gitlab::AppLogger
          )
        end

        # Rules are built per check rather than memoized. Resolving threshold
        # and interval through ApplicationRateLimiter.threshold/.interval on
        # every call lets application-setting changes and test stubs of the
        # public threshold(key)/interval(key) methods propagate to the labkit
        # path; a memoized Rule would freeze whichever value resolved on
        # first construction. The Redis round-trip in `check` dominates
        # construction cost, so the per-call allocation is not load-bearing.
        def build_rule(key, spec)
          ::Labkit::RateLimit::Rule.new(
            name: spec[:rule_name],
            characteristics: spec[:characteristics],
            limit: ::Gitlab::ApplicationRateLimiter.threshold(key),
            period: ::Gitlab::ApplicationRateLimiter.interval(key),
            action: spec[:action]
          )
        end

        # Builds the labkit identifier hash from a scope by routing AR-typed
        # values to the characteristic registered for their class (or its
        # base, via is_a?; a User populates :user, a DeployKey populates
        # :key via is_a? Key). Non-AR values (Strings, Symbols, Integers)
        # fill the remaining characteristics in order, skipping any
        # AR-typed slot the rule still has so primitive values never
        # accidentally land in :user/:project/etc.
        #
        # A rule with characteristics %i[project group user] called with
        # scope [project, user] yields {project: id, user: id}; labkit's
        # missing-value sentinel '_unknown_' fills :group, so the Redis
        # key shape is distinct from the Group case ({group: id, user: id}).
        def identifier_for(rule, scope)
          values = Array(scope).flatten.compact
          identifier = {}
          remaining_values = []

          values.each do |value|
            char = ar_characteristic_for(value, rule.characteristics)
            if char && !identifier.key?(char)
              identifier[char] = value.id
            else
              remaining_values << value
            end
          end

          primitive_chars = rule.characteristics.reject do |c|
            ar_characteristic_names.include?(c) || identifier.key?(c)
          end

          primitive_chars.zip(remaining_values).each do |char, value|
            next if value.nil?

            identifier[char] = value.to_s
          end

          identifier
        end

        # Maps AR-typed characteristic names to the class (or base class)
        # whose instances populate that slot. Routing is by direct class
        # match in the common case and falls back to is_a? for STI
        # subclasses (DeployKey populates :key via Key,
        # Namespaces::ProjectNamespace populates :namespace via Namespace).
        #
        # Iteration order is most-specific-first: Group must precede
        # Namespace so a Group instance routes to :group rather than the
        # base :namespace when a rule lists both characteristics. Add a
        # new entry here (subclasses above their bases) when introducing a
        # new AR-typed characteristic. Lazy-resolved so the module file
        # can be required before these constants are autoloaded.
        def ar_characteristic_types
          @ar_characteristic_types ||= {
            ::User => :user,
            ::Project => :project,
            ::Group => :group,
            ::Namespace => :namespace,
            ::Environment => :environment,
            ::Ci::PipelineSchedule => :ci_pipeline_schedule,
            ::Import::SourceUser => :import_source_user,
            ::Key => :key
          }.freeze
        end

        # Names of AR-typed characteristics, derived from the type table.
        # Used by identifier_for's primitive pass to reserve these slots
        # so non-AR scope values can't accidentally land in them.
        def ar_characteristic_names
          @ar_characteristic_names ||= ar_characteristic_types.values.to_set.freeze
        end

        # Returns the characteristic name a scope value should populate.
        # The common path is a direct class lookup; STI subclasses fall
        # through to an is_a? scan over the type table so DeployKey
        # populates :key via Key without enumerating every subclass.
        # Returns nil if the value isn't an instance of any registered
        # AR class or the rule has no characteristic for that class.
        def ar_characteristic_for(value, characteristics)
          char = ar_characteristic_types[value.class]
          return char if char && characteristics.include?(char)

          ar_characteristic_types.each do |klass, c|
            return c if value.is_a?(klass) && characteristics.include?(c)
          end
          nil
        end

        def window_boundary?(key)
          interval_seconds = ::Gitlab::ApplicationRateLimiter.interval(key)
          _, elapsed = Time.now.to_i.divmod(interval_seconds)
          elapsed < BOUNDARY_NOISE_SECONDS || elapsed >= interval_seconds - BOUNDARY_NOISE_SECONDS
        end

        # Resolved on every call rather than memoized at module scope.
        # Gitlab::Metrics.counter is itself memoized by name via the
        # Prometheus registry, so the per-call lookup is cheap and avoids
        # caching test doubles across examples.
        def shadow_counter
          ::Gitlab::Metrics.counter(
            :gitlab_rate_limiter_labkit_shadow_total,
            'Per-key agreement count between the labkit and legacy rate-limit paths during shadow validation.',
            { key: nil, agreement: nil, boundary: nil }
          )
        end

        # Records a labkit-handled key being called with an explicit
        # threshold or interval override. The labkit path can't honour
        # overrides (the Rule's limit/period are config-driven), so the
        # call routes back to legacy. Tracking gives us a path-to-removal
        # signal: which keys still see overrides, and how often.
        def record_override(key, threshold_override, interval_override)
          override_kind =
            if !threshold_override.nil? && !interval_override.nil?
              :both
            elsif !threshold_override.nil?
              :threshold
            else
              :interval
            end

          override_counter.increment(key: key, override: override_kind)
        end

        def override_counter
          ::Gitlab::Metrics.counter(
            :gitlab_rate_limiter_labkit_override_total,
            'Times a labkit-handled key was called with an explicit threshold or interval override, ' \
              'bypassing the labkit path.',
            { key: nil, override: nil }
          )
        end
      end
    end
  end
end
