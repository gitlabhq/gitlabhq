# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class MilestoneInputType < BaseInputObject
        graphql_name 'WorkItemWidgetMilestoneInput'

        argument :milestone_id,
          ::Types::GlobalIDType[::Milestone],
          required: :nullable,
          prepare: ->(id, _) { id.model_id unless id.nil? },
          description: 'Milestone to assign to the work item.'
      end
    end
  end
end
