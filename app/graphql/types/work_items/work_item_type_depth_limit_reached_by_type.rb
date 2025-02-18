# frozen_string_literal: true

module Types
  module WorkItems
    # rubocop: disable Graphql/AuthorizeTypes -- Parent node applies authorization
    class WorkItemTypeDepthLimitReachedByType < BaseObject
      graphql_name 'WorkItemTypeDepthLimitReachedByType'
      description 'Represents Depth limit reached for the allowed work item type.'

      field :work_item_type, ::Types::WorkItems::TypeType, null: false,
        description: 'Work item type.'

      field :depth_limit_reached, GraphQL::Types::Boolean,
        null: false,
        description: 'Indicates if maximum allowed depth has been reached for the descendant type.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
