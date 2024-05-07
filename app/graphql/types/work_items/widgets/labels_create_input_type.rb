# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class LabelsCreateInputType < BaseInputObject
        graphql_name 'WorkItemWidgetLabelsCreateInput'

        argument :label_ids, [::Types::GlobalIDType[::Label]],
          required: true,
          description: 'IDs of labels to be added to the work item.',
          prepare: ->(label_ids, _ctx) { label_ids.map(&:model_id) }
      end
    end
  end
end
