# frozen_string_literal: true

module Types
  class Namespace::PackageSettingsType < BaseObject
    graphql_name 'PackageSettings'

    description 'Namespace-level Package Registry settings'

    authorize :read_package_settings

    field :maven_duplicates_allowed, GraphQL::Types::Boolean, null: false, description: 'Indicates whether duplicate Maven packages are allowed for this namespace.'
    field :maven_duplicate_exception_regex, Types::UntrustedRegexp, null: true, description: 'When maven_duplicates_allowed is false, you can publish duplicate packages with names that match this regex. Otherwise, this setting has no effect.'
    field :generic_duplicates_allowed, GraphQL::Types::Boolean, null: false, description: 'Indicates whether duplicate generic packages are allowed for this namespace.'
    field :generic_duplicate_exception_regex, Types::UntrustedRegexp, null: true, description: 'When generic_duplicates_allowed is false, you can publish duplicate packages with names that match this regex. Otherwise, this setting has no effect.'
  end
end
