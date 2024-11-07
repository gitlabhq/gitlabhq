# frozen_string_literal: true
module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class StatusActionType < BaseObject
      graphql_name 'StatusAction'

      field :button_title, GraphQL::Types::String, null: true,
        description: 'Title for the button, for example: Retry the job.'
      field :confirmation_message, GraphQL::Types::String, null: true,
        description: 'Custom confirmation message for a manual job.',
        experiment: { milestone: '17.0' }
      field :icon, GraphQL::Types::String, null: true,
        description: 'Icon used in the action button.'
      field :id, GraphQL::Types::String, null: false,
        description: 'ID for a status action.',
        extras: [:parent]
      field :method, GraphQL::Types::String, null: true,
        description: 'Method for the action, for example: :post.',
        resolver_method: :action_method
      field :path, GraphQL::Types::String, null: true,
        description: 'Path for the action.'
      field :title, GraphQL::Types::String, null: true,
        description: 'Title for the action, for example: Retry.'

      def id(parent:)
        # parent is a SimpleDelegator
        "#{parent.subject.class.name}-#{parent.id}"
      end

      def action_method
        object[:method]
      end
    end
  end
end
