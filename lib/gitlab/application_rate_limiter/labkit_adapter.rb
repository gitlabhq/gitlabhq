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
          identifier = identifier_for(scope)
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
          limiter = limiter_for(key)
          identifier = identifier_for(scope)
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

        # Builds the labkit identifier hash from a characteristic-keyed
        # scope hash ({ user: current_user, project: project, sha: 'abc' }).
        # AR-backed values contribute their primary key, primitives
        # (String/Symbol) their string form. Nil values are dropped so
        # labkit's '_unknown_' sentinel fills the slot, making
        # { group: nil } and an omitted :group produce the same Redis key:
        # a rule with characteristics %i[project group user] called with
        # { project: project, user: user } yields {project: id, user: id},
        # and '_unknown_' fills :group, so the Redis key shape is distinct
        # from the Group case ({group: id, user: id}).
        def identifier_for(scope)
          scope.each_with_object({}) do |(characteristic, value), identifier|
            next if value.nil?

            identifier[characteristic] = value.is_a?(::ActiveRecord::Base) ? value.id : value.to_s
          end
        end
      end
    end
  end
end
