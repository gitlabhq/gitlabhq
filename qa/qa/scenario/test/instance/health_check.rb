# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Instance
        class HealthCheck < All
          tags :health_check

          pipeline_mappings test_on_cng: ["cng-qa-min-redis-version"], test_on_omnibus: ["health-check"]
        end
      end
    end
  end
end
