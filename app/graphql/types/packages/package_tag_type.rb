# frozen_string_literal: true

module Types
  module Packages
    class PackageTagType < BaseObject
      graphql_name 'PackageTag'
      description 'Represents a package tag'
      authorize :read_package

      field :created_at, Types::TimeType, null: false, description: 'Created date.'
      field :id, GraphQL::Types::ID, null: false, description: 'ID of the tag.'
      field :name, GraphQL::Types::String, null: false, description: 'Name of the tag.'
      field :updated_at, Types::TimeType, null: false, description: 'Updated date.'
    end
  end
end
