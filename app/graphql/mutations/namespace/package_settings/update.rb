# frozen_string_literal: true

module Mutations
  module Namespace
    module PackageSettings
      class Update < Mutations::BaseMutation
        include Mutations::ResolvesNamespace

        graphql_name 'UpdateNamespacePackageSettings'

        authorize :create_package_settings

        argument :namespace_path,
                GraphQL::ID_TYPE,
                required: true,
                description: 'The namespace path where the namespace package setting is located.'

        argument :maven_duplicates_allowed,
                GraphQL::BOOLEAN_TYPE,
                required: false,
                description: copy_field_description(Types::Namespace::PackageSettingsType, :maven_duplicates_allowed)

        argument :maven_duplicate_exception_regex,
                Types::UntrustedRegexp,
                required: false,
                description: copy_field_description(Types::Namespace::PackageSettingsType, :maven_duplicate_exception_regex)

        argument :generic_duplicates_allowed,
                GraphQL::BOOLEAN_TYPE,
                required: false,
                description: copy_field_description(Types::Namespace::PackageSettingsType, :generic_duplicates_allowed)

        argument :generic_duplicate_exception_regex,
                Types::UntrustedRegexp,
                required: false,
                description: copy_field_description(Types::Namespace::PackageSettingsType, :generic_duplicate_exception_regex)

        field :package_settings,
              Types::Namespace::PackageSettingsType,
              null: true,
              description: 'The namespace package setting after mutation.'

        def resolve(namespace_path:, **args)
          namespace = authorized_find!(namespace_path: namespace_path)

          result = ::Namespaces::PackageSettings::UpdateService
            .new(container: namespace, current_user: current_user, params: args)
            .execute

          {
            package_settings: result.payload[:package_settings],
            errors: result.errors
          }
        end

        private

        def find_object(namespace_path:)
          resolve_namespace(full_path: namespace_path)
        end
      end
    end
  end
end
