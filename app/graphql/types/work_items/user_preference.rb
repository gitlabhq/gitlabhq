# frozen_string_literal: true

module Types
  module WorkItems
    class UserPreference < BaseObject
      graphql_name 'WorkItemTypesUserPreference'

      authorize :read_namespace

      field :namespace,
        type: ::Types::NamespaceType,
        null: false,
        description: 'Namespace for the user preference.'

      field :work_item_type,
        type: ::Types::WorkItems::TypeType,
        null: true,
        description: 'Type assigned to the work item.'

      field :sort,
        type: ::Types::WorkItems::SortEnum,
        null: true,
        description: 'Sort order for work item lists.'

      field :display_settings,
        type: GraphQL::Types::JSON,
        null: true,
        description: 'Display settings for the work item lists.'

      def sort
        object.sort&.to_sym
      end
    end
  end
end
