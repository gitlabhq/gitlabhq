# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Instance
        class CloudActivation < All
          tags :cloud_activation

          pipeline_mappings test_on_omnibus: %w[cloud-activation]
        end
      end
    end
  end
end
