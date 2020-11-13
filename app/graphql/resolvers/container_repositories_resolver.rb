# frozen_string_literal: true

module Resolvers
  class ContainerRepositoriesResolver < BaseResolver
    include ::Mutations::PackageEventable

    type Types::ContainerRepositoryType, null: true

    argument :name, GraphQL::STRING_TYPE,
              required: false,
              description: 'Filter the container repositories by their name'

    def resolve(name: nil)
      ContainerRepositoriesFinder.new(user: current_user, subject: object, params: { name: name })
                                 .execute
                                 .tap { track_event(:list_repositories, :container) }
    end
  end
end
