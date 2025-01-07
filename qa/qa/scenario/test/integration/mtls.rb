# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        class Mtls < Test::Instance::All
          tags :mtls

          pipeline_mappings test_on_omnibus: %w[mtls]
        end
      end
    end
  end
end
