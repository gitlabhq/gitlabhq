# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes
      class MilestoneType < BaseObject
        graphql_name 'WorkItemWidgetMilestone'
        description 'Represents a milestone widget'

        implements ::Types::WorkItems::WidgetInterface

        field :milestone,
          ::Types::MilestoneType,
          null: true,
          description: 'Milestone of the work item.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
