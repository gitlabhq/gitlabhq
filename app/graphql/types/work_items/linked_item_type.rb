# frozen_string_literal: true

module Types
  module WorkItems
    class LinkedItemType < BaseObject
      graphql_name 'LinkedWorkItemType'

      authorize :read_work_item

      field :link_created_at, ::Types::TimeType,
        description: 'Timestamp the link was created.', null: false,
        method: :issue_link_created_at

      field :work_item_state, ::Types::WorkItemStateEnum,
        description: 'State of the linked work item.', null: false, method: :state

      field :link_id, ::Types::GlobalIDType[::WorkItems::RelatedWorkItemLink],
        description: 'Global ID of the link.', null: false,
        method: :issue_link_id
      field :link_type, GraphQL::Types::String,
        description: 'Type of link.', null: false,
        method: :issue_link_type
      field :link_updated_at, ::Types::TimeType,
        description: 'Timestamp the link was updated.', null: false,
        method: :issue_link_updated_at
      field :work_item, ::Types::WorkItemType,
        description: 'Linked work item.', null: true

      def work_item
        object
      end
    end
  end
end
