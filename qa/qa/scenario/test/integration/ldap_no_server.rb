# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        class LDAPNoServer < Test::Instance::All
          tags :ldap_no_server

          pipeline_mappings test_on_omnibus: %w[ldap-no-server]
        end
      end
    end
  end
end
