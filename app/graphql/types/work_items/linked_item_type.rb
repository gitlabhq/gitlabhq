# frozen_string_literal: true

module Types
  module WorkItems
    # rubocop:disable Graphql/AuthorizeTypes
    class LinkedItemType < BaseObject
      graphql_name 'LinkedWorkItemType'

      field :link_created_at, Types::TimeType,
        description: 'Timestamp the link was created.', null: false
      field :link_id, ::Types::GlobalIDType[::WorkItems::RelatedWorkItemLink],
        description: 'Global ID of the link.', null: false
      field :link_type, GraphQL::Types::String,
        description: 'Type of link.', null: false
      field :link_updated_at, Types::TimeType,
        description: 'Timestamp the link was updated.', null: false
      field :work_item, Types::WorkItemType,
        description: 'Linked work item.', null: false
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
