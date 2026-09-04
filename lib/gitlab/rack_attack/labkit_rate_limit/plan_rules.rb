# frozen_string_literal: true

module Gitlab
  module RackAttack
    module LabkitRateLimit
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
        end
      end
    end
  end
end

::Gitlab::RackAttack::LabkitRateLimit::PlanRules.prepend_mod
