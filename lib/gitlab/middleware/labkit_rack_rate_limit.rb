# frozen_string_literal: true

module Gitlab
  module Middleware
    # Runs Labkit::RateLimit alongside Rack::Attack during the migration off the
    # legacy stack. Per-cohort wip flags drive three states, mirroring
    # Gitlab::ApplicationRateLimiter::LabkitAdapter:
    #
    #   shadow off              : labkit does not run; Rack::Attack alone decides.
    #   shadow on, enforce off  : labkit runs and its block decision is recorded
    #                             against Rack::Attack's, but never acted on.
    #   shadow on, enforce on   : labkit additionally blocks. On a block whose cohort
    #                             enforces it renders the byte-identical legacy 429
    #                             and short-circuits; otherwise the request falls
    #                             through to Rack::Attack, which still enforces.
    #
    # Mounted directly above Rack::Attack (see config/application.rb), so it wraps it
    # and observes every request after Warden has resolved auth. On the way in it
    # builds a ClassifiedRequest of raw request facts and runs every limiter's full,
    # ordered rule set over them (cohort gates enforcement, not which rules exist).
    # Each limiter returns its first matching rule's decision; labkit blocks the
    # request when any of those decisions is a block whose cohort enforces. On the
    # way back up it compares labkit's block decision against Rack::Attack's.
    #
    # The middleware blocks only when an enforcing cohort's rule blocks; otherwise it
    # never blocks. The request's own errors propagate (@app.call is not wrapped);
    # the labkit decision is guarded, so a failure there is tracked and falls open to
    # Rack::Attack rather than affecting the response. labkit itself also fails open
    # on any Redis error.
    #
    # Collaborators are referenced lazily inside methods rather than via class-body
    # constants: this file is require_dependency'd from config/application.rb before
    # Zeitwerk autoloading is active, so it must not resolve autoloaded siblings at
    # load time.
    class LabkitRackRateLimit
      def initialize(app)
        @app = app
      end

      def call(env)
        decision = guard { run(env) }

        return decision[:response] if decision && decision[:response]

        status, headers, body = @app.call(env)

        guard { record(env, decision) } if decision

        [status, headers, body]
      end

      private

      # Inbound: build the request facts and run them through every limiter's full
      # ordered rule set. Each limiter returns its first matching rule's result (an
      # :allow for a bypassed/skipped/unmatched request, otherwise the matched
      # throttle's decision). Returns those results (compared on the way out) and the
      # byte-identical 429 to return in place of calling the app (nil unless an
      # enforcing cohort's rule blocks), or nil when the shadow did not run (no active
      # cohort, or a guarded failure).
      def run(env)
        return if active_cohorts.empty?

        request = build_request(env)
        context = with_isolated_throttle_instrumentation { request.labkit_facts }
        results = limiters.all.values.map { |limiter| limiter.check(context) }
        { results: results, response: enforced_response(results) }
      end

      # Outbound: compare labkit's block decision against Rack::Attack's for the same
      # request. The comparison is on the decision, not per-throttle counts: labkit
      # blocked iff one of its rules blocked, Rack::Attack blocked iff one of the
      # throttles it annotated onto the env exceeded its limit.
      def record(env, decision)
        divergence.record(
          labkit_result: blocking_result(decision[:results]),
          rackattack_throttle_data: env['rack.attack.throttle_data'] || {}
        )
      end

      # The byte-identical legacy 429 for the first blocking rule whose cohort
      # enforces, or nil when none enforces a block. The counter was already
      # incremented in the limiter check, so reading the decision here never
      # double-counts. Mirrors Gitlab::RackAttack's throttled_responder so a promoted
      # throttle is indistinguishable from the legacy stack to clients.
      def enforced_response(results)
        blocked = results.find do |result|
          # An unmatched or synthetic-allow result carries no rule, so its cohort can
          # only be looked up once blocked? has confirmed a matched throttle blocked
          # (a block always carries its rule). Testing blocked? first also preserves
          # the short-circuit the &&-chain relied on before entry was hoisted out.
          next false unless blocked?(result)

          entry = entry_for_rule(result.rule.name)
          entry && enforce_enabled?(entry.cohort)
        end
        return unless blocked

        # The 429's RateLimit-Name is the real throttle name (Entry#name), not the
        # matched rule name: a companion rule (e.g. authenticated_web_frontend) is the
        # same throttle as its base (throttle_authenticated_web), so the header stays
        # byte-identical to the legacy Rack::Attack responder for that throttle.
        headers = ::Gitlab::RackAttack::RequestThrottleData
          .from_labkit_result(name: entry_for_rule(blocked.rule.name).name, result: blocked)
          &.throttled_response_headers

        [429, { 'Content-Type' => 'text/plain' }.merge(headers || {}), [::Gitlab::Throttle.rate_limiting_response_text]]
      end

      # The first rule that blocked, or nil. A dry-run throttle's rule is :log, so it
      # never reports :block; the synthetic bypass/skip/runner rules and an unmatched
      # request are :allow. So neither a tracked-only throttle nor a short-circuited
      # request is ever read as a block.
      def blocking_result(results)
        results.find { |result| blocked?(result) }
      end

      def blocked?(result)
        result.action == :block
      end

      # The throttle Entry a matched Labkit rule name resolves to, memoized on first
      # use (the first request, past initialization, so the require_dependency'd
      # middleware never resolves its registry sibling at load time). Keyed by Labkit
      # rule name, companion rules included (a companion like authenticated_web_frontend
      # resolves to its base throttle_authenticated_web), so both the enforce cohort
      # (Entry#cohort) and the 429 header name (Entry#name) come from the base throttle.
      # A synthetic rule has no entry, but a synthetic rule never blocks, so it is
      # never looked up here.
      def entry_for_rule(rule_name)
        @entries_by_rule ||= registry.by_rule_name
        @entries_by_rule[rule_name]
      end

      # ClassifiedRequest#labkit_facts no longer writes
      # Gitlab::Instrumentation::Throttle.safelist: it computes the requester
      # discriminator from the auth primitive rather than throttled_identifer, so it
      # carries no instrumentation side effect. This guard is now defensive - if any
      # fact the shadow reads were to touch the safelist again, it is saved and
      # restored (only when actually changed) so the shadow leaves the real request's
      # instrumentation untouched; Rack::Attack sets the safelist itself via its own
      # auth path regardless.
      def with_isolated_throttle_instrumentation
        instrumentation = ::Gitlab::Instrumentation::Throttle
        original = instrumentation.safelist
        yield
      ensure
        instrumentation.safelist = original unless instrumentation.safelist == original
      end

      def active_cohorts
        registry.cohorts.select { |cohort| shadow_enabled?(cohort) }.to_set
      end

      # The flag symbol is built inline (not assigned to a local first) so the
      # MarkUsedFeatureFlags cop sees a dynamic-symbol literal and optimistically
      # marks every flag with this prefix used; a local variable would read as an
      # lvar and the cop would report the flags unused. Mirrors the Stage 2a
      # adapter (Gitlab::ApplicationRateLimiter::LabkitAdapter).
      def shadow_enabled?(cohort)
        # rubocop:disable Gitlab/FeatureFlagKeyDynamic -- bases enumerated in ThrottleRegistry, with matching YAMLs in config/feature_flags/wip/
        ::Feature.enabled?(
          :"rate_limiter_use_labkit_#{registry.flag_basis(cohort)}", ::Feature.current_request, type: :wip
        )
        # rubocop:enable Gitlab/FeatureFlagKeyDynamic
      end

      def enforce_enabled?(cohort)
        # rubocop:disable Gitlab/FeatureFlagKeyDynamic -- bases enumerated in ThrottleRegistry, with matching YAMLs in config/feature_flags/wip/
        ::Feature.enabled?(
          :"rate_limiter_use_labkit_#{registry.flag_basis(cohort)}_enforce", ::Feature.current_request, type: :wip
        )
        # rubocop:enable Gitlab/FeatureFlagKeyDynamic
      end

      # The request that classifies itself for labkit, built from a dup of the env
      # with PATH_INFO normalized the way Rack::Attack normalizes it before
      # classifying (we run first), to avoid a spurious path divergence without
      # mutating the shared env. We call ActionDispatch::Journey::Router::Utils
      # directly (what Rack::Attack::PathNormalizer resolves to in a Rails app).
      # ClassifiedRequest is the same shape as Rack::Attack::Request but carries no
      # Rack::Attack dependency.
      def build_request(env)
        shadow_env = env.dup
        shadow_env['PATH_INFO'] = ::ActionDispatch::Journey::Router::Utils.normalize_path(shadow_env['PATH_INFO'])
        ::Gitlab::RackAttack::LabkitRateLimit::ClassifiedRequest.new(shadow_env)
      end

      def guard
        yield
      rescue StandardError => e
        ::Gitlab::ErrorTracking.track_exception(e)
        nil
      end

      def registry
        ::Gitlab::RackAttack::LabkitRateLimit::ThrottleRegistry
      end

      def limiters
        ::Gitlab::RackAttack::LabkitRateLimit::Limiters
      end

      def divergence
        ::Gitlab::RackAttack::LabkitRateLimit::Divergence
      end
    end
  end
end
