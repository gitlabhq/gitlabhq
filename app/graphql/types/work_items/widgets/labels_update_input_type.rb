# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class LabelsUpdateInputType < BaseInputObject
        graphql_name 'WorkItemWidgetLabelsUpdateInput'

        argument :add_label_ids, [::Types::GlobalIDType[::Label]],
          required: false,
          description: 'Global IDs of labels to be added to the work item.',
          prepare: ->(label_ids, _ctx) { label_ids.map(&:model_id) }
        argument :remove_label_ids, [::Types::GlobalIDType[::Label]],
          required: false,
          description: 'Global IDs of labels to be removed from the work item.',
          prepare: ->(label_ids, _ctx) { label_ids.map(&:model_id) }
      end
    end
  end
end
