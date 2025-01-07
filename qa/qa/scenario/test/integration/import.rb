# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        class Import < Test::Instance::All
          tags :import

          pipeline_mappings test_on_omnibus: %w[importers]
        end
      end
    end
  end
end
