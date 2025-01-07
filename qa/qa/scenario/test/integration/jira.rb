# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        class Jira < Test::Instance::All
          tags :jira

          pipeline_mappings test_on_omnibus: %w[jira]
        end
      end
    end
  end
end
