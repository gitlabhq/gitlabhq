# frozen_string_literal: true

module Types
  module AlertManagement
    class IntegrationTypeEnum < BaseEnum
      graphql_name 'AlertManagementIntegrationType'
      description 'Values of types of integrations'

      value 'PROMETHEUS', 'Prometheus integration.', value: :prometheus
      value 'HTTP', 'Integration with any monitoring tool.', value: :http
    end
  end
end
