# frozen_string_literal: true

module Types
  class PackageType < BaseObject
    graphql_name 'Package'
    description 'Represents a package'
    authorize :read_package

    field :id, GraphQL::ID_TYPE, null: false, description: 'The ID of the package'
    field :name, GraphQL::STRING_TYPE, null: false, description: 'The name of the package'
    field :created_at, Types::TimeType, null: false, description: 'The created date'
    field :updated_at, Types::TimeType, null: false, description: 'The update date'
    field :version, GraphQL::STRING_TYPE, null: true, description: 'The version of the package'
    field :package_type, Types::PackageTypeEnum, null: false, description: 'The type of the package'
  end
end
