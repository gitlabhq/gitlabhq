# frozen_string_literal: true

module Types
  module WorkItems
    class TypeType < BaseObject
      graphql_name 'WorkItemType'

      authorize :read_work_item_type

      field :icon_name, GraphQL::Types::String, null: true,
                                                description: 'Icon name of the work item type.'
      field :id, Types::GlobalIDType[::WorkItems::Type], null: false,
                                                         description: 'Global ID of the work item type.'
      field :name, GraphQL::Types::String, null: false,
                                           description: 'Name of the work item type.'
    end
  end
end
