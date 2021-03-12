# frozen_string_literal: true

module Types
  module AlertManagement
    class DomainFilterEnum < BaseEnum
      graphql_name 'AlertManagementDomainFilter'
      description  'Filters the alerts based on given domain'

      value 'operations', description: 'Alerts for operations domain.'
      value 'threat_monitoring', description: 'Alerts for threat monitoring domain.'
    end
  end
end
