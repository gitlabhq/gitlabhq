# frozen_string_literal: true

module Types
  module Projects
    class ServiceTypeEnum < BaseEnum
      graphql_name 'ServiceType'

      class << self
        private

        def type_description(type)
          "#{type} type"
        end
      end

      # This prepend must stay here because the dynamic block below depends on it.
      prepend_mod # rubocop: disable Cop/InjectEnterpriseEditionModule

      ::Integration.available_integration_types(include_dev: false).each do |type|
        value type.underscore.upcase, value: type, description: type_description(type)
      end
    end
  end
end
