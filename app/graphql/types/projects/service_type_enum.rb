# frozen_string_literal: true

module Types
  module Projects
    class ServiceTypeEnum < BaseEnum
      graphql_name 'ServiceType'

      ::Integration.available_integration_types(include_dev: false).each do |type|
        value type.underscore.upcase, value: type, description: "#{type} type"
      end
    end
  end
end
