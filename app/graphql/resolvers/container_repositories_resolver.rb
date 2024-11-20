# frozen_string_literal: true

module Resolvers
  class ContainerRepositoriesResolver < BaseResolver
    include ::Mutations::PackageEventable

    type Types::ContainerRegistry::ContainerRepositoryType, null: true

    argument :name, GraphQL::Types::String,
      required: false,
      description: 'Filter the container repositories by their name.'

    argument :sort, Types::ContainerRegistry::ContainerRepositorySortEnum,
      description: 'Sort container repositories by the criteria.',
      required: false,
      default_value: :created_desc

    def resolve(name: nil, sort: nil)
      ContainerRepositoriesFinder.new(user: current_user, subject: object, params: { name: name, sort: sort })
                                 .execute
                                 .tap { track_event(:list_repositories, :container) }
    end
  end
end
