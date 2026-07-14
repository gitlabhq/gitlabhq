# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        class SecretsManager < Test::Instance::All
          tags :secrets_manager
          pipeline_mappings test_on_cng: %w[cng-secrets-manager]
        end
      end
    end
  end
end
