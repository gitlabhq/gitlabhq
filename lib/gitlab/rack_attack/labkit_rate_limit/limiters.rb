# frozen_string_literal: true

module Gitlab
  module RackAttack
    module LabkitRateLimit
      # Builds the Labkit::RateLimit::Limiter instances the middleware runs, one per
      # distinct limiter the registry assigns throttles to:
      #
      #   rack_request                 - the general request throttles
      #   rack_request_protected_paths - the protected-path throttles, which
      #                                  overlap general ones and so need their
      #                                  own counters
      #
      # (EE adds a third limiter for the incident-management throttle, which
      # likewise overlaps the general web throttle.) The limiters are built straight
      # from the registry, so an added limiter needs no change here.
      #
      # Every rule is always built, regardless of cohort: cohort gates enforcement
      # (whether a matched block becomes a 429, decided in the middleware), not
      # presence. Building only the active cohorts' rules would break the ordering -
      # a git request would fall through to the web rule whenever the git cohort was
      # inactive - so the full, ordered rule set is always present and classifies
      # every request the same way at any rollout stage.
      #
      # Each throttle's rule matches the facts ClassifiedRequest exposes (the
      # registry's :match) and counts by its discriminators (the :characteristics).
      # Both are taken straight from the registry in the shape the SDK's Rule expects,
      # including the presence gate the registry bakes into the match.
      # Within a limiter the rules are evaluated in registry order. The SDK counts
      # every matching rule (labkit >= 4.0 evaluates all matches; nothing terminates
      # on match alone), so each throttle declaring :claims in the registry pairs
      # its counting rule with a terminating :skip claim of the same match (see
      # build_rules). Ordering plus the claims reproduce Rack::Attack's exclusions:
      # the first throttle to match counts the request and stops evaluation before
      # the general rules below it. Limit and
      # period are resolved per check from the same Gitlab::Throttle options the
      # Rack::Attack throttle uses, so the two stacks stay in lock-step even when an
      # admin changes a limit at runtime.
      #
      # Three synthetic rules sit ahead of the throttle rules. They carry no
      # Rack::Attack throttle and exist to express, as ordered terminating rules,
      # the conditions Rack::Attack expresses as predicate exclusions:
      #
      #   bypass  - the safelist header; skips every throttle (mirrors the
      #             Rack::Attack safelist).
      #   skip    - the should_be_skipped? requests (internal API, health, container
      #             registry, plus EE's Geo/virtual-registry checks), for unauthenticated
      #             requests only (requester_id and runner_id both nil - those are the
      #             throttles that exclude them). One rule per ThrottleRegistry.skip_match
      #             (a path matcher, plus EE's verified_geo_request rule), each named by
      #             its skip_matches key.
      #   runner  - runner- or job-token-authenticated requests on the runner-jobs
      #             API path (/api/v4/jobs/*), excluded from the authenticated API
      #             throttle (Rack::Attack's !runner_jobs_request?, mirrored by the
      #             runner_jobs fact). The fact carries the auth method, not just
      #             requester presence, so a PAT- or OAuth-authenticated request on
      #             that path (a bot polling job status) is NOT skipped and falls
      #             through to the authenticated API throttle, exactly as
      #             Rack::Attack counts it. The requester gate keeps the edge cases
      #             right: an anonymous request to that path falls through to the
      #             unauthenticated API throttle, and a runner-token request (fact
      #             true, requester nil) escapes every rule - no requester for the
      #             authenticated rules, runner_id present blocking the
      #             unauthenticated ones - as it does on every other path.
      #
      # user_allowlist (GITLAB_THROTTLE_USER_ALLOWLIST) is the fourth, on every
      # limiter: a full bypass, wider than Rack::Attack's safelist only for rules
      # that cannot fire on a user anyway (the dead collector path, EE's
      # Alertmanager-only incident throttle). See
      # gitlab-com/gl-infra/production-engineering#29320 and #29563.
      #
      # All four are :skip: they terminate evaluation while permitting, so the
      # throttle rules below never run, and they perform no Redis write (the
      # bypass volume made these counters the majority of the shadow's Redis
      # load; see gitlab-com/gl-infra/production-engineering#29052). The
      # short-circuit stays observable via calls_total{action="skip"}.
      #
      # The limiters are memoized: the rule set is fixed, and the only per-request
      # variation (the limit/period values, the matched facts) is read live inside
      # the check. In phase 2 this is replaced by config loaded through labkit.
      module Limiters
        BYPASS_RULE_NAME = 'bypass_header'
        RUNNER_RULE_NAME = 'runner_jobs'
        ALLOWLIST_RULE_NAME = 'user_allowlist'

        class << self
          # Every limiter, keyed by name, with the full ordered rule set built.
          # Memoized: the rule set does not vary by request. Names come from the
          # registry (ThrottleRegistry.by_limiter), so EE-added limiters are served
          # unchanged.
          def all
            @all ||= ThrottleRegistry.by_limiter.to_h do |limiter_name, entries|
              [limiter_name, build(limiter_name, entries)]
            end
          end

          # Test hook: limiters are captured at first build, so specs that change
          # the registry or the limiter shape must clear the memo.
          def reset!
            @all = nil
          end

          private

          def build(limiter_name, entries)
            rules = synthetic_rules(limiter_name) + entries.flat_map { |entry| build_rules(entry) }

            ::Labkit::RateLimit::Limiter.new(
              name: limiter_name,
              rules: rules,
              redis: ::Gitlab::Redis::RateLimiting,
              logger: ::Gitlab::AppLogger
            )
          end

          # The terminating :skip rules ahead of the throttle rules. bypass and
          # user_allowlist are on every limiter (the safelist and the allowlist
          # skip all throttles); skip is on the limiters whose unauthenticated
          # throttles exclude should_be_skipped? paths; the runner-jobs rule is on
          # the general limiter, whose authenticated API throttle excludes runner-
          # and job-token-authenticated requests on the runner-jobs path (the
          # runner_jobs fact).
          def synthetic_rules(limiter_name)
            rules = [skip_rule(BYPASS_RULE_NAME, { bypass: true }), user_allowlist_rule].compact

            if [ThrottleRegistry::GENERAL, ThrottleRegistry::PROTECTED].include?(limiter_name)
              ThrottleRegistry.skip_matches.each do |name, match|
                rules << skip_rule(name, match)
              end
            end

            if limiter_name == ThrottleRegistry::GENERAL
              rules << skip_rule(RUNNER_RULE_NAME, { runner_jobs: true, requester_id: /./ })
            end

            rules
          end

          # A synthetic terminating rule: :skip permits and terminates without a
          # Redis operation. The SDK still requires the limit/period/characteristics
          # kwargs, but they are inert on :skip rules.
          def skip_rule(name, match)
            ::Labkit::RateLimit::Rule.new(
              name: name,
              match: match,
              characteristics: [:ip],
              limit: 0,
              period: 60,
              action: :skip
            )
          end

          # IDs are stringified to match the requester_id fact; the requester_type
          # gate keeps a DeployToken sharing an allowlisted user's numeric id counted.
          def user_allowlist_rule
            ids = ::Gitlab::RackAttack.user_allowlist.to_a
            return if ids.empty?

            skip_rule(ALLOWLIST_RULE_NAME, { requester_type: 'user', requester_id: { oneOf: ids.map(&:to_s) } })
          end

          # A throttle declaring :claims in the registry builds as an ordered
          # pair: a counting rule, then a terminating :skip with the same match
          # (the claim). The SDK evaluates every matching rule and terminates
          # only on :skip or an over-limit :limit rule, so without the claim a
          # specialized request would also be counted by the general rules below
          # it (a git request is also a web request), breaking parity with
          # Rack::Attack's !throttle_*? exclusions. The claim restores them: the
          # counting rule debits its counter, then the claim terminates
          # evaluation while permitting. A :limit rule over its limit blocks
          # before its claim is reached, so enforcement is unchanged; a claimed
          # under-limit result reports the claim rule (matched, :allow, no info)
          # with the counted evaluation still readable via Result#evaluations.
          # The registry only declares the claim; its match is derived here from
          # the entry's own, so it cannot drift from the counting rule's.
          #
          # An enforced throttle counts with :limit; a dry-run throttle (named in
          # GITLAB_THROTTLE_DRY_RUN, so Gitlab::RackAttack.track? is true) counts
          # with :log, which records whether the hit would have exceeded but never
          # blocks. The claim is the same in both shapes; the dry-run one keeps
          # its historical _dry_run_bypass name.
          def build_rules(entry)
            dry_run = ::Gitlab::RackAttack.track?(entry.name)
            rules = [throttle_rule(entry, dry_run ? :log : :limit)]
            rules << (dry_run ? dry_run_bypass_rule(entry) : claim_rule(entry)) if entry.claims?
            rules
          end

          def throttle_rule(entry, action)
            options = entry.definition.options

            ::Labkit::RateLimit::Rule.new(
              name: entry.rule_name,
              match: entry.match,
              characteristics: entry.characteristics,
              limit: ->(_context) { resolve_option(options[:limit]) },
              period: ->(_context) { resolve_option(options[:period]) },
              action: action
            )
          end

          # The terminating :skip paired with a dry-run throttle's :log rule. Same
          # match as the :log rule so it claims exactly the requests that throttle
          # would have; the preceding :log rule does the counting.
          def dry_run_bypass_rule(entry)
            skip_rule("#{entry.rule_name}_dry_run_bypass", entry.match)
          end

          # The terminating :skip paired with an enforced throttle's :limit rule.
          # Same match, so it claims exactly the requests that rule counted and
          # stops them reaching the general rules below.
          def claim_rule(entry)
            skip_rule("#{entry.rule_name}_claim", entry.match)
          end

          # Rack::Attack options carry either a plain value (e.g. the hardcoded
          # product-analytics limit) or a proc taking the Rack request and
          # reading application settings. The procs ignore the request argument,
          # so passing nil resolves the live setting; labkit coerces the result
          # to an Integer (periods arrive as ActiveSupport::Duration).
          def resolve_option(option)
            value = option.respond_to?(:call) ? option.call(nil) : option
            value.to_i
          end
        end
      end
    end
  end
end
