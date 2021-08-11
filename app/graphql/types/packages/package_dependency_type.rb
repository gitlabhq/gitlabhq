# frozen_string_literal: true
# this model does not have any kind of authorization so we disable it
# rubocop:disable Graphql/AuthorizeTypes

module Types
  module Packages
    class PackageDependencyType < BaseObject
      graphql_name 'PackageDependency'
      description 'Represents a package dependency.'

      field :id, ::Types::GlobalIDType[::Packages::Dependency], null: false, description: 'ID of the dependency.'
      field :name, GraphQL::Types::String, null: false, description: 'Name of the dependency.'
      field :version_pattern, GraphQL::Types::String, null: false, description: 'Version pattern of the dependency.'
    end
  end
end
