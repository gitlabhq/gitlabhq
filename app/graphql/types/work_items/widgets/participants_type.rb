# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Participants shown consistently to all users for performance.
      # rubocop:disable Graphql/AuthorizeTypes -- see above
      class ParticipantsType < BaseObject
        graphql_name 'WorkItemWidgetParticipants'
        description 'Represents a participants widget'

        implements ::Types::WorkItems::WidgetInterface

        field :participants, ::Types::UserType.connection_type,
          null: true,
          description: 'Participants in the work item.'

        def participants
          object.participants(current_user)
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
