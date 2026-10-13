# frozen_string_literal: true

module Gitlab
  module Instrumentation
    class RateLimitState
      STATE = :rate_limit_state

      class << self
        # Every rule that counted, in evaluation order, then the rule that
        # ended the check if one did. A result that counted nothing and skipped
        # nothing (unmatched, or a fail-open error) names no rule and is
        # dropped.
        def track(results_by_limiter)
          return unless ::Gitlab::SafeRequestStore.active?

          results_by_limiter.each do |limiter, result|
            result.evaluations.each { |evaluation| state << entry(limiter, evaluation.rule, result_for(evaluation)) }

            # A :skip rule terminates without counting, so it has no evaluation
            # of its own. Recording it last says what stopped the check, and
            # what had already been counted before it did.
            state << entry(limiter, result.rule, 'skip') if result.skipped?
          end
        end

        # Reads without initializing: every request and every Sidekiq job calls
        # this, and only the rack middleware ever tracks, so writing here would
        # allocate for nothing on most of them.
        def payload
          tracked = ::Gitlab::SafeRequestStore[STATE]
          return {} if tracked.blank?

          { STATE => tracked }
        end

        private

        # One string rather than parallel arrays: Elasticsearch keeps no
        # pairing between two array fields on a document, so a rule and a
        # result queried together could come from different entries. The
        # limiter leads because two limiters can carry the same rule name.
        def entry(limiter, rule, result)
          "#{limiter}:#{rule.name}:#{result}"
        end

        # The counted values of the rule_evaluations_total metric, derived the
        # way labkit derives them for that metric, so a log line and the metric
        # pivot on the same key.
        def result_for(evaluation)
          return 'allow' unless evaluation.exceeded?
          return 'banned' if evaluation.rule.ban_for

          evaluation.rule.action == :limit ? 'block' : 'log'
        end

        def state
          ::Gitlab::SafeRequestStore[STATE] ||= []
        end
      end
    end
  end
end
