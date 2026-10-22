# frozen_string_literal: true

module Gitlab
  module RateLimit
    # The tier-aware request throttles and the flags gating them. EE-only, so CE
    # reports nothing in play: reading either side from CE raises under FOSS.
    module PlanRules
      class << self
        def flags
          []
        end

        def active?
          false
        end

        def for_limiter(_limiter_name)
          []
        end

        # Rule name => the RateLimit-Name its responses carry instead.
        # rubocop:disable Gitlab/NoCodeCoverageComment -- overridden and tested in EE
        # :nocov:
        def concealed_rules
          {}
        end
        # :nocov:
        # rubocop:enable Gitlab/NoCodeCoverageComment
      end
    end
  end
end

::Gitlab::RateLimit::PlanRules.prepend_mod
