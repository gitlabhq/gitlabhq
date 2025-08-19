# frozen_string_literal: true

module Types
  module WorkItems
    class HierarchyFilterInputType < BaseInputObject
      graphql_name 'HierarchyFilterInput'

      argument :parent_ids, [::Types::GlobalIDType[::WorkItem]],
        description: 'Filter work items by global IDs of their parent items (maximum is 100 items).',
        required: false,
        prepare: ->(global_ids, _ctx) { GitlabSchema.parse_gids(global_ids, expected_type: ::WorkItem).map(&:model_id) }

      argument :include_descendant_work_items, GraphQL::Types::Boolean,
        description: 'Whether to include work items of descendant parents when filtering by parent_ids.',
        required: false

      argument :parent_wildcard_id, ::Types::WorkItems::ParentWildcardIdEnum,
        required: false,
        description: 'Filter by parent ID wildcard. Incompatible with parentIds.',
        experiment: { milestone: '18.3' }

      validates mutually_exclusive: [:parent_ids, :parent_wildcard_id]
    end
  end
end
