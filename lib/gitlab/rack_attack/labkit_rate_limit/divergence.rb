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
          def record(labkit_result:, rackattack_throttle_data:)
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
          end

          private

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
