# frozen_string_literal: true

module Types
  module Projects
    # TODO: Remove in 17.0, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108418
    class ServiceTypeEnum < BaseEnum
      graphql_name 'ServiceType'

      class << self
        private

        def type_description(name, type)
          "#{type} type"
        end

        def integration_names
          Integration.available_integration_names(
            include_instance_specific: false, include_dev: false, include_disabled: true
          )
        end
      end

      # This prepend must stay here because the dynamic block below depends on it.
      prepend_mod

      integration_names.each do |name|
        type = "#{name.camelize}Service"
        domain_value = Integration.integration_name_to_type(name)
        value type.underscore.upcase, value: domain_value, description: type_description(name, type)
      end
    end
  end
end

Types::Projects::ServiceTypeEnum.prepend_mod
