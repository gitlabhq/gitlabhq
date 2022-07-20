# frozen_string_literal: true

module Mutations
  module WorkItems
    module UpdateArguments
      extend ActiveSupport::Concern

      included do
        argument :id, ::Types::GlobalIDType[::WorkItem],
                 required: true,
                 description: 'Global ID of the work item.'
        argument :state_event, Types::WorkItems::StateEventEnum,
                 description: 'Close or reopen a work item.',
                 required: false
        argument :title, GraphQL::Types::String,
                 required: false,
                 description: copy_field_description(Types::WorkItemType, :title)
        argument :description_widget, ::Types::WorkItems::Widgets::DescriptionInputType,
                 required: false,
                 description: 'Input for description widget.'
        argument :weight_widget, ::Types::WorkItems::Widgets::WeightInputType,
                 required: false,
                 description: 'Input for weight widget.'
        argument :hierarchy_widget, ::Types::WorkItems::Widgets::HierarchyUpdateInputType,
                 required: false,
                 description: 'Input for hierarchy widget.'
      end
    end
  end
end
