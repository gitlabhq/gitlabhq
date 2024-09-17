# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes -- reason above
      class EmailParticipantsType < BaseObject
        graphql_name 'WorkItemWidgetEmailParticipants'
        description 'Represents email participants widget'

        implements Types::WorkItems::WidgetInterface

        field :email_participants,
          [GraphQL::Types::String],
          null: true,
          description: 'Collection of email participants associated with the work item.',
          method: :email_participants_emails
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
