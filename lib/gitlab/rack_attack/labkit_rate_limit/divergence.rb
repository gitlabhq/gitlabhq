# frozen_string_literal: true

module Gitlab
  module RackAttack
    module LabkitRateLimit
      # Compares the labkit shadow's block decision for a request against
      # Rack::Attack's, and records the result.
      #
      # The comparison is on the decision, not per-throttle counts: labkit blocked
      # iff one of its rules blocked, and Rack::Attack blocked iff one of the
      # throttles it annotated onto the env (rack.attack.throttle_data, set for every
      # throttle it evaluated) exceeded its limit. This is what the migration needs
      # to know - "does labkit block the same requests Rack::Attack does" - now that
      # the rules are an independent, faithful re-expression of the throttles rather
      # than a per-throttle classification to reconcile.
      #
      # Window-edge skew between labkit's TTL-based reset and Rack::Attack's
      # epoch-aligned window produces sub-second block disagreements that are not
      # bugs; those are tagged boundary: true so go/no-go queries can exclude them
      # while keeping the data observable. Fail-open labkit results are not
      # disagreements and are skipped.
      module Divergence
        BOUNDARY_NOISE_SECONDS = 1

        class << self
          def record(labkit_result:, rackattack_throttle_data:, labkit_results: [], facts: {})
            return if labkit_result&.error?

            exceeded = rackattack_throttle_data.find { |_name, data| rackattack_throttled?(data) }

            labkit_blocked = labkit_result&.action == :block
            rackattack_blocked = !exceeded.nil?

            # The overwhelming common case is neither stack blocking; recording it
            # would tick once per request and swamp the diverge signal the rollout
            # gate reads. Only a block on either side is worth a data point: every
            # disagreement, and every block both stacks agree on.
            return unless labkit_blocked || rackattack_blocked

            agreement = labkit_blocked == rackattack_blocked ? :match : :diverge
            boundary = window_boundary?(boundary_period(labkit_result, exceeded))

            counter.increment(throttle: throttle_label(labkit_result, exceeded), agreement: agreement,
              boundary: boundary)

            return unless agreement == :diverge

            log_divergence(labkit_result: labkit_result, labkit_results: labkit_results, facts: facts,
              exceeded: exceeded, rackattack_throttle_data: rackattack_throttle_data)
          end

          private

          # Temporary sampled diagnostic for the divergence classes tracked in
          # https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/work_items/29362.
          # One structured line per sampled divergent decision, carrying what the
          # counter above cannot: both stacks' verdicts, counters, and
          # discriminators side by side, plus which rule each labkit limiter routed
          # the request to. Volume is operator-controlled: the ops flag is sampled
          # per request (percentage-of-actors on the request actor), and only
          # divergences are logged, so the line costs nothing until enabled.
          def log_divergence(labkit_result:, labkit_results:, facts:, exceeded:, rackattack_throttle_data:)
            return unless ::Feature.enabled?(:log_labkit_rack_divergence, ::Feature.current_request, type: :ops)

            # Fields with a standard name in Labkit::Fields are referenced by
            # constant; the rest are specific to this diagnostic and have no
            # standard equivalent.
            ::Gitlab::AppJsonLogger.info(
              ::Labkit::Fields::LOG_MESSAGE => 'Labkit rack shadow divergence',
              ::Labkit::Fields::CLASS_NAME => name,
              ::Labkit::Fields::REMOTE_IP => facts[:ip],
              ::Labkit::Fields::HTTP_METHOD => facts[:method],
              throttle: throttle_label(labkit_result, exceeded),
              labkit_blocked: labkit_result&.action == :block,
              rackattack_blocked: !exceeded.nil?,
              labkit_rules: labkit_results.filter_map { |result| labkit_rule_entry(result) },
              rackattack_throttles: rackattack_throttle_data.map do |throttle_name, data|
                rackattack_throttle_entry(throttle_name, data)
              end,
              requester_type: facts[:requester_type],
              requester_id: facts[:requester_id],
              runner_id: facts[:runner_id],
              path: facts[:path]
            )
          end

          # One matched labkit rule as log fields. Every limiter contributes its
          # first matching rule, so together these show where labkit routed the
          # request - a synthetic skip/bypass match is as diagnostic as a block.
          # Unmatched limiters carry no rule and are dropped; a skip rule performs
          # no Redis operation, so its count/limit are nil.
          def labkit_rule_entry(result)
            return unless result.rule

            {
              rule: result.rule.name,
              action: result.action.to_s,
              count: result.info&.count&.to_f,
              limit: result.info&.resolved_limit&.to_i
            }
          end

          # One Rack::Attack throttle annotation as log fields. throttle_data holds
          # an entry for every throttle whose discriminator resolved on this
          # request, so a throttle labkit matched that is absent here means
          # Rack::Attack did not even count the request - itself a finding. The
          # discriminator is stringified: Rack::Attack discriminators mix Integers
          # (user ids) and Strings (ips, "type:id" pairs), and a log field must
          # keep one type.
          def rackattack_throttle_entry(throttle_name, data)
            {
              throttle: throttle_name,
              discriminator: data[:discriminator].to_s,
              count: data[:count].to_i,
              limit: data[:limit].to_i
            }
          end

          # Label the disagreement by whichever side decided: labkit's blocking rule,
          # else the Rack::Attack throttle that exceeded, else "none" (both allowed).
          def throttle_label(labkit_result, exceeded)
            return "throttle_#{labkit_result.rule.name}" if labkit_result&.rule
            return exceeded.first if exceeded

            'none'
          end

          # The period to test for window-edge noise: the blocking labkit rule's, or
          # the exceeded Rack::Attack throttle's, or none (no block on either side, so
          # no boundary skew to tag).
          def boundary_period(labkit_result, exceeded)
            return labkit_result.info.resolved_period if labkit_result&.info
            return exceeded.last[:period].to_i if exceeded

            0
          end

          # Rack::Attack throttles when the post-increment count strictly exceeds
          # the limit, matching labkit's `count > resolved_limit`.
          def rackattack_throttled?(data)
            return false unless data

            data[:count].to_i > data[:limit].to_i
          end

          def window_boundary?(interval_seconds)
            return false if interval_seconds <= 0

            _, elapsed = Time.now.to_i.divmod(interval_seconds)
            elapsed < BOUNDARY_NOISE_SECONDS || elapsed >= interval_seconds - BOUNDARY_NOISE_SECONDS
          end

          def counter
            ::Gitlab::Metrics.counter(
              :gitlab_rate_limiter_labkit_rack_shadow_total,
              'Agreement between the labkit shadow middleware and Rack::Attack block decisions during migration.',
              { throttle: nil, agreement: nil, boundary: nil }
            )
          end
        end
      end
    end
  end
end
