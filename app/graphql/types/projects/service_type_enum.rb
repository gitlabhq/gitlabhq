# frozen_string_literal: true

module Types
  module Projects
    class ServiceTypeEnum < BaseEnum
      graphql_name 'ServiceType'

      ::Service.services_types.each do |service_type|
        value service_type.underscore.upcase, value: service_type
      end
    end
  end
end
