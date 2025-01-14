# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Instance
        class HealthCheck < All
          tags :health_check

          pipeline_mappings test_on_cng: ["cng-qa-min-redis-version"]
        end
      end
    end
  end
end
