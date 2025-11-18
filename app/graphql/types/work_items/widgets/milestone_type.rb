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

        def self.authorization_scopes
          super + [:ai_workflows]
        end

        field :milestone,
          ::Types::MilestoneType,
          skip_type_authorization: [:read_milestone],
          scopes: [:api, :read_api, :ai_workflows],
          null: true,
          description: 'Milestone of the work item.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
