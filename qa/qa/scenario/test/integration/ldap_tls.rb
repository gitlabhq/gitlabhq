# rubocop:todo Naming/FileName
# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        class LDAPTLS < Test::Instance::All
          tags :ldap_tls

          pipeline_mappings test_on_omnibus: %w[ldap-tls]
        end
      end
    end
  end
end

# rubocop:enable Naming/FileName
