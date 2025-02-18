# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as we scope by `.visible_participants`
      # rubocop:disable Graphql/AuthorizeTypes -- see above
      class ParticipantsType < BaseObject
        graphql_name 'WorkItemWidgetParticipants'
        description 'Represents a participants widget'

        implements ::Types::WorkItems::WidgetInterface

        field :participants, ::Types::UserType.connection_type,
          null: true,
          description: 'Participants in the work item.'

        def participants
          object.visible_participants(current_user)
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
