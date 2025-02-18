# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes -- reason above
      class CustomStatusType < BaseObject
        graphql_name 'WorkItemWidgetCustomStatus'
        description 'Represents Custom Status widget'

        implements ::Types::WorkItems::WidgetInterface

        # TODO change the ID to CustomStatus model ID while implementing
        # https://gitlab.com/gitlab-org/gitlab/-/issues/498393
        field :id, ::Types::GlobalIDType[::WorkItems::Widgets::CustomStatus],
          null: false,
          experiment: { milestone: '17.8' },
          description: 'ID of the Custom Status.'

        field :name, GraphQL::Types::String,
          null: true,
          experiment: { milestone: '17.8' },
          description: 'Name of the Custom Status.'

        field :icon_name, GraphQL::Types::String,
          null: true,
          experiment: { milestone: '17.8' },
          description: 'Icon name of the Custom Status.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
