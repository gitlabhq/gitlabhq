# frozen_string_literal: true

module Types
  module Packages
    class PackageTagType < BaseObject
      graphql_name 'PackageTag'
      description 'Represents a package tag'
      authorize :read_package

      field :id, GraphQL::Types::ID, null: false, description: 'The ID of the tag.'
      field :name, GraphQL::Types::String, null: false, description: 'The name of the tag.'
      field :created_at, Types::TimeType, null: false, description: 'The created date.'
      field :updated_at, Types::TimeType, null: false, description: 'The updated date.'
    end
  end
end
