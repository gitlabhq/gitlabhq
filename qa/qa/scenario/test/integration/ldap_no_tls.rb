# rubocop:todo Naming/FileName
# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        class LDAPNoTLS < Test::Instance::All
          tags :ldap_no_tls

          pipeline_mappings test_on_omnibus: %w[ldap-no-tls]
        end
      end
    end
  end
end

# rubocop:enable Naming/FileName
