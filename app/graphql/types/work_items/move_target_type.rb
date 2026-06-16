# frozen_string_literal: true

module Types
  module WorkItems
    # rubocop:disable Graphql/AuthorizeTypes -- authorization happens via the parent NamespaceType / source work item types.
    class MoveTargetType < BaseObject
      graphql_name 'WorkItemMoveTarget'

      authorize_granular_token permissions: :read_work_item,
        boundary: :group, boundary_type: :group

      description 'Valid target work item types and a suggested target for ' \
        'moving work items of a given source type to a different namespace.'

      field :source_type, ::Types::WorkItems::TypeType,
        null: false,
        description: 'Source work item type the suggestion is computed for.'

      field :suggested_target_type, ::Types::WorkItems::TypeType,
        null: true,
        description: 'Recommended target work item type in the destination namespace. ' \
          'Matches by global ID first (covers system-defined and converted custom types ' \
          'across namespaces), then falls back to matching by name. ' \
          'Returns `null` when no clear match exists; callers should let the user pick manually.'

      field :valid_target_types, [::Types::WorkItems::TypeType],
        null: false,
        description: 'Work item types in the destination namespace that the source type ' \
          'can be moved into. Includes the destination type that equals the source by ' \
          'global ID (if present) and the source type\'s conversion targets that exist ' \
          'in the destination namespace.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
