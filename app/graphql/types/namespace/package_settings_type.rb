# frozen_string_literal: true

module Types
  class Namespace::PackageSettingsType < BaseObject
    graphql_name 'PackageSettings'

    description 'Namespace-level Package Registry settings'

    authorize :admin_package

    field :generic_duplicate_exception_regex, Types::UntrustedRegexp,
      null: true,
      description: 'When generic_duplicates_allowed is false, you can publish duplicate packages with names that ' \
        'match this regex. Otherwise, this setting has no effect.'
    field :generic_duplicates_allowed, GraphQL::Types::Boolean,
      null: false,
      description: 'Indicates whether duplicate generic packages are allowed for this namespace.'
    field :maven_duplicate_exception_regex, Types::UntrustedRegexp,
      null: true,
      description: 'When maven_duplicates_allowed is false, you can publish duplicate packages with names that ' \
        'match this regex. Otherwise, this setting has no effect.'
    field :maven_duplicates_allowed, GraphQL::Types::Boolean,
      null: false,
      description: 'Indicates whether duplicate Maven packages are allowed for this namespace.'
    field :maven_package_requests_forwarding, GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates whether Maven package forwarding is allowed for this namespace.'
    field :npm_package_requests_forwarding, GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates whether npm package forwarding is allowed for this namespace.'
    field :nuget_duplicate_exception_regex, Types::UntrustedRegexp,
      null: true,
      description: 'When nuget_duplicates_allowed is false, you can publish duplicate packages with names that ' \
        'match this regex. Otherwise, this setting has no effect. '
    field :nuget_duplicates_allowed, GraphQL::Types::Boolean,
      null: false,
      description: 'Indicates whether duplicate NuGet packages are allowed for this namespace.'
    field :pypi_package_requests_forwarding, GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates whether PyPI package forwarding is allowed for this namespace.'
    field :terraform_module_duplicate_exception_regex, Types::UntrustedRegexp,
      null: true,
      description: 'When terraform_module_duplicates_allowed is false, you can publish duplicate packages with ' \
        'names that match this regex. Otherwise, this setting has no effect.'
    field :terraform_module_duplicates_allowed, GraphQL::Types::Boolean,
      null: false,
      description: 'Indicates whether duplicate Terraform packages are allowed for this namespace.'

    field :lock_maven_package_requests_forwarding, GraphQL::Types::Boolean,
      null: false,
      description: 'Indicates whether Maven package forwarding is locked for all descendent namespaces.'
    field :lock_npm_package_requests_forwarding, GraphQL::Types::Boolean,
      null: false,
      description: 'Indicates whether npm package forwarding is locked for all descendent namespaces.'
    field :lock_pypi_package_requests_forwarding, GraphQL::Types::Boolean,
      null: false,
      description: 'Indicates whether PyPI package forwarding is locked for all descendent namespaces.'

    field :maven_package_requests_forwarding_locked, GraphQL::Types::Boolean,
      null: false,
      method: :maven_package_requests_forwarding_locked?,
      description: 'Indicates whether Maven package forwarding settings are locked by a parent namespace.'
    field :npm_package_requests_forwarding_locked, GraphQL::Types::Boolean,
      null: false,
      method: :npm_package_requests_forwarding_locked?,
      description: 'Indicates whether npm package forwarding settings are locked by a parent namespace.'
    field :pypi_package_requests_forwarding_locked, GraphQL::Types::Boolean,
      null: false,
      method: :pypi_package_requests_forwarding_locked?,
      description: 'Indicates whether PyPI package forwarding settings are locked by a parent namespace.'

    field :nuget_symbol_server_enabled, GraphQL::Types::Boolean,
      null: false,
      description: 'Indicates wheather the NuGet symbol server is enabled for this namespace.'
  end
end
