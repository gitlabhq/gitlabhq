# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        class OAuth < Test::Instance::All
          tags :oauth

          pipeline_mappings test_on_omnibus: %w[oauth]
        end
      end
    end
  end
end
