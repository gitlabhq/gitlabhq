# frozen_string_literal: true

module Types
  module Projects
    # TODO: Remove in 17.0, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108418
    class ServiceTypeEnum < BaseEnum
      graphql_name 'ServiceType'

      class << self
        private

        def graphql_value(name)
          "#{name.upcase}_SERVICE"
        end

        def domain_value(name)
          Integration.integration_name_to_type(name)
        end

        def value_description(name)
          "#{Integration.integration_name_to_model(name).title} integration"
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
        value graphql_value(name), value: domain_value(name), description: value_description(name) # rubocop:disable Graphql/EnumValues -- Cop falsely identifies we must call upcase. Enum value is upcased in #graphql_value
      end
    end
  end
end

Types::Projects::ServiceTypeEnum.prepend_mod
