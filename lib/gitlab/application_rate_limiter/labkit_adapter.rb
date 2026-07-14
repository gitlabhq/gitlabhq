# frozen_string_literal: true

module Gitlab
  module ApplicationRateLimiter
    # Routes ApplicationRateLimiter checks through Labkit::RateLimit::Limiter.
    #
    # Every key registered in ApplicationRateLimiter.rate_limits must also be
    # registered in SupportedRateLimits. A guardrail spec asserts that coverage
    # so Labkit can be the authoritative rate-limiting path.
    #
    # The labkit Redis key shape is "labkit:rl:...".
    module LabkitAdapter
      class << self
        # Whether the spec for +key+ describes a count_distinct (SADD/SCARD)
        # rule. Used by the dispatch to decide whether IncrementPerActionedResource
        # calls can be routed to the labkit path without semantic drift.
        def set_mode?(key)
          spec = SupportedRateLimits.all[key]
          !spec.nil? && !spec[:count_distinct].nil?
        end

        # Whether the spec for +key+ accumulates a Float cost (resource-usage)
        # rather than counting calls. Cost-mode dispatch passes the per-request
        # consumption as labkit `check(cost:)`.
        def cost_mode?(key)
          spec = SupportedRateLimits.all[key]
          !spec.nil? && !!spec[:cost_mode]
        end

        # Increments the labkit counter and returns labkit's boolean decision
        # (whether the request should be blocked).
        #
        # +context+ carries per-call data that doesn't live in the registry:
        # +:resource_id+ supplies the SADD member for count_distinct
        # (set-mode) rules; ignored for INCR-mode rules. A per-call
        # +:threshold+ / +:interval+ overrides the registry value via the
        # Rule's one-arity `limit:`/`period:` callables. The whole hash is
        # forwarded as labkit `rule_context:`.
        #
        # +cost+ is the float amount a cost-mode (resource-usage) entry adds to
        # the counter, passed to labkit as `check(cost:)`. It does not travel
        # through rule_context, which only resolves limit/period and never moves
        # the counter. Ignored (labkit defaults to 1) for count/set-mode entries.
        #
        # @return [Boolean] labkit's decision (exceeded?)
        def run!(key, scope:, context: {}, cost: nil)
          spec = SupportedRateLimits.all.fetch(key)
          rule = build_rule(key, spec)
          identifier = identifier_for(rule, scope)

          member_slot = spec[:count_distinct]
          resource_id = context[:resource_id]
          identifier[member_slot] = resource_id if member_slot && resource_id

          # Cost-mode (resource-usage) entries add the measured cost; everything
          # else is a plain count, labkit's default cost of 1. A zero-cost job
          # must not create an empty counter, mirroring the resource-usage
          # strategy, and only cost-mode can be 0.
          check_cost = spec[:cost_mode] ? cost.to_f : 1
          return false if check_cost == 0

          result = build_limiter(spec, rule).check(identifier, cost: check_cost, rule_context: context)

          return false if result.error?

          result.exceeded?
        end

        # Reads the labkit counter without incrementing and returns labkit's
        # boolean decision. Mirrors {#run!} for callers that route through
        # ApplicationRateLimiter#peek. The labkit Redis key shape is identical
        # to {#run!} so a peek observes the same counter that a paired non-peek
        # call site increments. count_distinct (set-mode) rules do not need the
        # SET member on peek; labkit reads SCARD on the bucket key directly.
        #
        # @return [Boolean] labkit's decision (exceeded?)
        def run_peek!(key, scope:, context: {})
          spec = SupportedRateLimits.all.fetch(key)
          rule = build_rule(key, spec)
          result = build_limiter(spec, rule).peek(
            identifier_for(rule, scope),
            rule_context: context
          )

          return false if result.error?

          result.exceeded?
        end

        private

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
          # limit/period are one-arity callables resolved per check. A caller
          # that supplies the value via rule_context wins: a set-mode
          # (count_distinct) entry its per-call override, a threshold_from_caller
          # entry (web_hook_calls*) its :threshold, a resource-usage entry both
          # :threshold and :interval, and any key called with a per-call
          # threshold:/interval: override. Otherwise the value falls back to the
          # registry, resolved fresh per check so application-setting changes and
          # test stubs propagate. The fallback is lazy on purpose: resource-usage
          # keys aren't in ApplicationRateLimiter.rate_limits (interval(key)
          # would raise InvalidKeyError), but their ctx always carries both
          # values, so the registry is never consulted for them.
          limit = ->(ctx) { ctx&.dig(:threshold) || ::Gitlab::ApplicationRateLimiter.threshold(key) }
          period = ->(ctx) { ctx&.dig(:interval) || ::Gitlab::ApplicationRateLimiter.interval(key) }

          ::Labkit::RateLimit::Rule.new(
            name: spec[:rule_name],
            characteristics: spec[:characteristics],
            limit: limit,
            period: period,
            action: spec[:action],
            count_distinct: spec[:count_distinct]
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
      end
    end
  end
end
