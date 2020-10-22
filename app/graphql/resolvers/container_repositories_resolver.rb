# frozen_string_literal: true

module Resolvers
  class ContainerRepositoriesResolver < BaseResolver
    type Types::ContainerRepositoryType, null: true

    argument :name, GraphQL::STRING_TYPE,
              required: false,
              description: 'Filter the container repositories by their name'

    def resolve(name: nil)
      ContainerRepositoriesFinder.new(user: current_user, subject: object, params: { name: name })
                                 .execute
                                 .tap { track_event(:list_repositories, :container) }
    end

    private

    def track_event(event, scope)
      ::Packages::CreateEventService.new(nil, current_user, event_name: event, scope: scope).execute
      ::Gitlab::Tracking.event(event.to_s, scope.to_s)
    end
  end
end
