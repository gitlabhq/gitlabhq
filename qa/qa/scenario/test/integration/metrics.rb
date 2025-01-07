# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        class Metrics < Test::Instance::All
          tags :metrics

          pipeline_mappings test_on_omnibus: %w[metrics]
        end
      end
    end
  end
end
