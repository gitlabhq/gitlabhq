# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Instance
        class Vue3Rollout < All
          tags :vue3_rollout

          pipeline_mappings test_on_cng: %w[cng-vue3-rollout], test_on_omnibus: %w[vue3-rollout]
        end
      end
    end
  end
end
