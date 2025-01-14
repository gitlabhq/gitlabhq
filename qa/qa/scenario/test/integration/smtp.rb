# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        class SMTP < Test::Instance::All
          tags :smtp

          pipeline_mappings test_on_omnibus: %w[smtp]
        end
      end
    end
  end
end
