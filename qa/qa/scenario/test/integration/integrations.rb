# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        class Integrations < Test::Instance::All
          tags :integrations

          pipeline_mappings test_on_omnibus: %w[integrations]
        end
      end
    end
  end
end
