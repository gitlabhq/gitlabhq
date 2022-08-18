# frozen_string_literal: true

module Types
  module AlertManagement
    class DomainFilterEnum < BaseEnum
      graphql_name 'AlertManagementDomainFilter'
      description  'Filters the alerts based on given domain'

      value 'operations', description: 'Alerts for operations domain.'
      value 'threat_monitoring',
        description: 'Alerts for threat monitoring domain.',
        deprecated: {
          reason: 'Network policies are deprecated and will be removed in GitLab 16.0',
          milestone: '15.0'
        }
    end
  end
end
