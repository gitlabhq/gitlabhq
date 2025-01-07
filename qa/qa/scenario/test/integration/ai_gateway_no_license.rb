# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        class AiGatewayNoLicense < QA::Scenario::Test::Instance::All
          tags :ai_gateway_no_license

          pipeline_mappings test_on_omnibus: %w[ai-gateway-no-license]
        end
      end
    end
  end
end
