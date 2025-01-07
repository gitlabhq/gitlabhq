# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        class InstanceSAML < Test::Instance::All
          tags :instance_saml

          pipeline_mappings test_on_omnibus: %w[instance-saml]
        end
      end
    end
  end
end
