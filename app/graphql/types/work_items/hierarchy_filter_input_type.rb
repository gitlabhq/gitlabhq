# frozen_string_literal: true

module Types
  module WorkItems
    class HierarchyFilterInputType < BaseInputObject
      graphql_name 'HierarchyFilterInput'

      argument :parent_ids, [::Types::GlobalIDType[::WorkItem]],
        description: 'Filter work items by global IDs of their parent items (maximum is 100 items).',
        required: true,
        prepare: ->(global_ids, _ctx) { GitlabSchema.parse_gids(global_ids, expected_type: ::WorkItem).map(&:model_id) }

      argument :include_descendant_work_items, GraphQL::Types::Boolean,
        description: 'Whether to include work items of descendant parents when filtering by parent_ids.',
        required: false
    end
  end
end
