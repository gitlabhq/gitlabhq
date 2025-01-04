# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        class Registry < Test::Instance::All
          tags :registry

          pipeline_mappings test_on_cng: ["cng-registry"]
        end
      end
    end
  end
end
