# frozen_string_literal: true

module Gitlab
  module ApplicationRateLimiter
    # Routes ApplicationRateLimiter checks through Labkit::RateLimit::Limiter.
    #
    # Every key registered in SupportedRateLimits is handled by labkit, whose
    # decision is authoritative. Keys not in the registry are not handled here
    # (the caller falls through to "not throttled").
    #
    # The labkit Redis key shape is "labkit:rl:...".
    module LabkitAdapter
      class << self
        # Whether +key+ has a registry entry and is therefore routed through
        # labkit. Guards {#run!}/{#run_peek!}, whose +fetch+ would otherwise
        # raise for an unregistered key.
        def handled?(key)
          SupportedRateLimits.all.key?(key)
        end

        # Whether the rule for +key+ describes a count_distinct (SADD/SCARD)
        # rule. Used by the dispatch to decide whether resource-based calls can
        # be routed to the labkit path without semantic drift.
        def set_mode?(key)
          SupportedRateLimits.rule_for(key).count_distinct.present?
        rescue KeyError
          false
        end

        # Whether +key+ accumulates a Float cost (resource-usage)
        # rather than counting calls. Cost-mode dispatch passes the per-request
        # consumption as labkit `check(cost:)`.
        def cost_mode?(key)
          SupportedRateLimits.cost_mode?(key)
        end

        def period_for(key)
          SupportedRateLimits.period_for(key)
        end

        # Increments the labkit counter and returns labkit's boolean decision
        # (whether the request should be blocked).
        #
        # +context+ carries per-call data that doesn't live in the registry:
        # +:resource_id+ supplies the SADD member for count_distinct
        # (set-mode) rules; ignored for INCR-mode rules. A per-call
        # +:threshold+ / +:interval+ overrides the registry value via the
        # Rule's one-arity `limit:`/`period:` callables. +:bypass_header+,
        # when present, is also copied onto the identifier (not just
        # rule_context) so the synthetic bypass rule can match it against
        # '1' (see SupportedRateLimits#bypass_rule_for). The whole hash is
        # forwarded as labkit `rule_context:`.
        #
        # +cost+ is the float amount a cost-mode (resource-usage) entry adds to
        # the counter, passed to labkit as `check(cost:)`. It does not travel
        # through rule_context, which only resolves limit/period and never moves
        # the counter. Ignored (labkit defaults to 1) for count/set-mode entries.
        #
        # @return [Boolean] labkit's decision (exceeded?)
        def run!(key, scope:, context: {}, cost: nil)
          rule = SupportedRateLimits.rule_for(key)
          limiter = limiter_for(key)
          identifier = identifier_for(rule.characteristics, scope)
          apply_bypass_header!(identifier, context)

          member_slot = rule.count_distinct
          resource_id = context[:resource_id]
          identifier[member_slot] = resource_id if member_slot && resource_id

          # Cost-mode (resource-usage) entries add the measured cost; everything
          # else is a plain count, labkit's default cost of 1. A zero-cost job
          # must not create an empty counter, mirroring the resource-usage
          # strategy, and only cost-mode can be 0.
          check_cost = SupportedRateLimits.cost_mode?(key) ? cost.to_f : 1
          return false if check_cost == 0

          result = limiter.check(identifier, cost: check_cost, rule_context: context)

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
          rule = SupportedRateLimits.rule_for(key)
          limiter = limiter_for(key)
          identifier = identifier_for(rule.characteristics, scope)
          apply_bypass_header!(identifier, context)

          result = limiter.peek(identifier, rule_context: context)

          return false if result.error?

          result.exceeded?
        end

        private

        # Copies :bypass_header from +context+ onto +identifier+ only when the
        # caller supplied it: true for anything going through #throttled?,
        # false for callers that bypass it (e.g. resource_usage_throttled?).
        def apply_bypass_header!(identifier, context)
          identifier[:bypass_header] = context[:bypass_header] if context.key?(:bypass_header)
        end

        def limiter_for(key)
          SupportedRateLimits.limiter_for(key)
        end

        # Builds the labkit identifier hash from a scope.
        #
        # The target contract is a characteristic-keyed hash
        # ({ user: current_user, project: project, sha: 'abc' }): AR-backed
        # values contribute their primary key, primitives (String/Symbol)
        # their string form. Nil values are dropped so labkit's '_unknown_'
        # sentinel fills the slot, making { group: nil } and an omitted
        # :group produce the same Redis key.
        #
        # Positional scopes (array or bare value) are still accepted while
        # call sites migrate to the hash contract; the positional path below
        # is deleted once the migration lands. It routes AR-typed values to
        # the characteristic registered for their class (or its base, via
        # is_a?; a User populates :user, a DeployKey populates :key via
        # is_a? Key), then fills the remaining non-AR characteristics in
        # order with the primitive values.
        #
        # Both paths fill missing characteristics identically: a rule with
        # characteristics %i[project group user] called with
        # { project: project, user: user } (or legacy [project, user])
        # yields {project: id, user: id}; labkit's missing-value sentinel
        # '_unknown_' fills :group, so the Redis key shape is distinct from
        # the Group case ({group: id, user: id}).
        def identifier_for(characteristics, scope)
          return hash_identifier_for(scope) if scope.is_a?(Hash)

          values = Array(scope).flatten.compact
          identifier = {}
          remaining_values = []

          values.each do |value|
            char = ar_characteristic_for(value, characteristics)
            if char && !identifier.key?(char)
              identifier[char] = value.id
            else
              remaining_values << value
            end
          end

          primitive_chars = characteristics.reject do |c|
            ar_characteristic_names.include?(c) || identifier.key?(c)
          end

          primitive_chars.zip(remaining_values).each do |char, value|
            next if value.nil?

            identifier[char] = value.to_s
          end

          identifier
        end

        def hash_identifier_for(scope)
          scope.each_with_object({}) do |(characteristic, value), identifier|
            next if value.nil?

            identifier[characteristic] = value.is_a?(::ActiveRecord::Base) ? value.id : value.to_s
          end
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
            ::Key => :key,
            ::MergeRequest => :merge_request
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

Gitlab::ApplicationRateLimiter::LabkitAdapter.prepend_mod
