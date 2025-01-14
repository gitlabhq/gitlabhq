# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        ##
        # Run test suite against any GitLab instance where Service Ping is disabled from gitlab.yml
        #
        class ServicePingDisabled < Test::Instance::All
          tags :service_ping_disabled

          pipeline_mappings test_on_omnibus: %w[service-ping-disabled]
        end
      end
    end
  end
end
