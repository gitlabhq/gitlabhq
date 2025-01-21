# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        class Registry < Test::Instance::All
          tags :registry

          pipeline_mappings test_on_cng: %w[cng-registry],
            test_on_omnibus: %w[registry],
            test_on_omnibus_nightly: %w[registry-with-cdn]
        end
      end
    end
  end
end
