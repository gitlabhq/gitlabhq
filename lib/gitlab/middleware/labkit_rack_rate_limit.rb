# frozen_string_literal: true

module Gitlab
  module Middleware
    # Enforces request rate limits with Labkit::RateLimit. On a block it renders
    # the byte-identical legacy 429 and short-circuits; otherwise the request
    # falls through to Rack::Attack, which is safelisted into a pass-through
    # (see Gitlab::RackAttack) and never blocks.
    #
    # Mounted directly above Rack::Attack (see config/application.rb), so it wraps it
    # and observes every request after Warden has resolved auth. On the way in it
    # builds a ClassifiedRequest of raw request facts and runs every limiter's full,
    # ordered rule set over them. Each limiter returns its first matching rule's
    # decision; labkit blocks the request when any of those decisions is a block. On
    # the way back up it adds the proactive RateLimit-* headers to non-429 responses,
    # taking over from RackAttackHeaders, which the safelist leaves with nothing to
    # read.
    #
    # The middleware blocks whenever a rule blocks, a registry rule and a rule with
    # no entry (a plan rule) alike; otherwise it never blocks. The request's own
    # errors propagate (@app.call is not wrapped); the labkit decision is guarded, so
    # a failure there is tracked and the request proceeds unthrottled, since
    # Rack::Attack no longer enforces anything to fall back on. labkit itself also
    # fails open on any Redis error.
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

        guard { annotate_rate_limit_headers(status, headers, decision[:results]) } if decision

        [status, headers, body]
      end

      private

      # Inbound: build the request facts and run them through every limiter's full
      # ordered rule set. Each limiter returns its first matching rule's result (an
      # :allow for a bypassed/skipped/unmatched request, otherwise the matched
      # throttle's decision). Returns those results (read again on the way out) and
      # the byte-identical 429 to return in place of calling the app (nil unless a
      # rule blocks), or nil on a guarded failure.
      def run(env)
        request = build_request(env)
        context = with_isolated_throttle_instrumentation { request.labkit_facts }
        results = limiters.all.values.map { |limiter| limiter.check(context) }
        { results: results, response: enforced_response(results) }
      end

      # Outbound: proactive RateLimit-* headers for non-429 responses (a 429 already
      # carries its own). Built from the counted evaluations, not each limiter's
      # reported result (an under-limit result reports the claim rule, which
      # carries no counter info).
      def annotate_rate_limit_headers(status, headers, results)
        return if status == 429

        evaluation = most_constraining_enforced(results)
        return unless evaluation

        rate_limit_headers = ::Gitlab::RackAttack::RequestThrottleData
          .from_labkit_result(name: throttle_name_for(evaluation.rule), result: evaluation)
          &.common_response_headers

        headers.merge!(rate_limit_headers) if rate_limit_headers
      end

      # The most constraining evaluation across all limiters, skipping :log rules: a
      # :log rule never enforces, so its quota is never advertised. Ties keep the
      # earlier evaluation, as Enumerable#min would.
      def most_constraining_enforced(results)
        evaluation = nil

        results.each do |result|
          result.evaluations.each do |counted|
            next if counted.rule.action == :log

            evaluation = counted if evaluation.nil? || counted < evaluation
          end
        end

        evaluation
      end

      # The byte-identical legacy 429 for the first blocking rule, or nil when none
      # blocks. A registry rule and a rule with no entry (a plan rule is only built
      # as :limit when its enforce flag is on) both block. The counter was already
      # incremented in the limiter check, so reading the decision here never
      # double-counts. Mirrors Gitlab::RackAttack's throttled_responder so a promoted
      # throttle is indistinguishable from the legacy stack to clients.
      def enforced_response(results)
        blocked = results.find { |result| blocked?(result) }
        return unless blocked

        headers = ::Gitlab::RackAttack::RequestThrottleData
          .from_labkit_result(name: throttle_name_for(blocked.rule), result: blocked)
          &.throttled_response_headers

        [429, { 'Content-Type' => 'text/plain' }.merge(headers || {}), [::Gitlab::Throttle.rate_limiting_response_text]]
      end

      # The RateLimit-Name for a rule: the backing throttle's name (Entry#name), not
      # the rule name, so a registry rule's headers stay byte-identical to the legacy
      # Rack::Attack responder, a rule with no entry carries its own name.
      def throttle_name_for(rule)
        entry_for_rule(rule.name)&.name || rule.name
      end

      # A dry-run throttle's rule is :log, so it never reports :block; the synthetic
      # bypass/skip/runner/claim rules and an unmatched request are :allow. So neither
      # a tracked-only throttle nor a short-circuited request is ever read as a block.
      def blocked?(result)
        result.action == :block
      end

      # The throttle Entry a matched Labkit rule name resolves to, memoized on first
      # use (the first request, past initialization, so the require_dependency'd
      # middleware never resolves its registry sibling at load time). Keyed by Labkit
      # rule name, from which the 429 header name (Entry#name, the backing throttle)
      # resolves. Synthetic and plan rules have no entry, so throttle_name_for falls
      # back to the rule's own name for them.
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
    end
  end
end
