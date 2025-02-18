# frozen_string_literal: true

module Types
  module WorkItems
    # rubocop: disable Graphql/AuthorizeTypes -- Parent node applies authorization
    class WorkItemTypeCountsByStateType < BaseObject
      graphql_name 'WorkItemTypeCountsByState'
      description 'Represents work item counts for the work item type'

      field :work_item_type, ::Types::WorkItems::TypeType, null: false,
        description: 'Work item type.'

      field :counts_by_state, ::Types::WorkItemStateCountsType, null: false,
        description: 'Total number of work items for the represented states.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
