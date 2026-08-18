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
    # way back up it compares labkit's block decision against Rack::Attack's. Once
    # fully enforced, it also adds the proactive RateLimit-* headers to non-429
    # responses, taking over from RackAttackHeaders, which the safelist leaves with
    # nothing to read.
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

        if decision
          guard { record(env, decision) }
          guard { annotate_rate_limit_headers(status, headers, decision[:results]) }
        end

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
        { facts: context, results: results, response: enforced_response(results) }
      end

      # Outbound: compare labkit's block decision against Rack::Attack's for the same
      # request. The comparison is on the decision, not per-throttle counts: labkit
      # blocked iff one of its rules blocked, Rack::Attack blocked iff one of the
      # throttles it annotated onto the env exceeded its limit. The full result set
      # and the request facts ride along for the sampled divergence log.
      def record(env, decision)
        divergence.record(
          labkit_result: blocking_result(decision[:results]),
          rackattack_throttle_data: env['rack.attack.throttle_data'] || {},
          labkit_results: decision[:results],
          facts: decision[:facts]
        )
      end

      # Outbound: proactive RateLimit-* headers for non-429 responses (a 429 already
      # carries its own), added only once labkit fully owns enforcement - until then
      # Rack::Attack still evaluates throttles and RackAttackHeaders builds these.
      # Built from the counted evaluations, not each limiter's reported result (an
      # under-limit result reports the claim rule, which carries no counter info);
      # min is the most constraining evaluation across all limiters.
      def annotate_rate_limit_headers(status, headers, results)
        return if status == 429 || !registry.fully_enforced?

        evaluation = results.flat_map(&:evaluations).min
        entry = evaluation && entry_for_rule(evaluation.rule.name)
        return unless entry

        rate_limit_headers = ::Gitlab::RackAttack::RequestThrottleData
          .from_labkit_result(name: entry.name, result: evaluation)
          &.common_response_headers

        headers.merge!(rate_limit_headers) if rate_limit_headers
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
          entry && registry.enforce_enabled?(entry.cohort)
        end
        return unless blocked

        # The 429's RateLimit-Name is the real throttle name (Entry#name), not the
        # matched rule name, so the header stays byte-identical to the legacy
        # Rack::Attack responder for that throttle.
        headers = ::Gitlab::RackAttack::RequestThrottleData
          .from_labkit_result(name: entry_for_rule(blocked.rule.name).name, result: blocked)
          &.throttled_response_headers

        [429, { 'Content-Type' => 'text/plain' }.merge(headers || {}), [::Gitlab::Throttle.rate_limiting_response_text]]
      end

      # The first rule that blocked, or nil. A dry-run throttle's rule is :log, so it
      # never reports :block; the synthetic bypass/skip/runner/claim rules and an
      # unmatched request are :allow. So neither a tracked-only throttle nor a
      # short-circuited request is ever read as a block.
      def blocking_result(results)
        results.find { |result| blocked?(result) }
      end

      def blocked?(result)
        result.action == :block
      end

      # The throttle Entry a matched Labkit rule name resolves to, memoized on first
      # use (the first request, past initialization, so the require_dependency'd
      # middleware never resolves its registry sibling at load time). Keyed by Labkit
      # rule name, from which both the enforce cohort (Entry#cohort) and the 429 header
      # name (Entry#name, the backing throttle) resolve. A synthetic rule has no entry,
      # but a synthetic rule never blocks, so it is never looked up here.
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
        registry.cohorts.select { |cohort| registry.shadow_enabled?(cohort) }.to_set
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
