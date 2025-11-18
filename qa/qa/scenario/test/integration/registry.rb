# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        class Registry < Test::Instance::All
          tags :registry

          pipeline_mappings test_on_cng: %w[cng-registry], test_on_omnibus: %w[registry]
        end
      end
    end
  end
end
