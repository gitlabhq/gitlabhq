# frozen_string_literal: true

module Types
  module Boards
    # rubocop: disable Graphql/AuthorizeTypes
    class BoardIssueInputBaseType < BoardIssuableInputBaseType
      argument :iids, [GraphQL::Types::String],
        required: false,
        description: 'List of IIDs of issues. For example `["1", "2"]`.'

      argument :milestone_title, GraphQL::Types::String,
        required: false,
        description: 'Filter by milestone title.'

      argument :assignee_username, [GraphQL::Types::String, { null: true }],
        required: false,
        description: 'Filter by assignee username.'

      argument :release_tag, GraphQL::Types::String,
        required: false,
        description: 'Filter by release tag.'

      argument :types, [Types::IssueTypeEnum],
        as: :issue_types,
        description: 'Filter by the given issue types.',
        required: false
      argument :work_item_type_ids,
        [::Types::GlobalIDType[::WorkItems::Type]],
        required: false,
        validates: { length: { maximum: ::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT } },
        description: 'Filter by work item type global IDs.',
        prepare: ->(global_ids, _ctx) { global_ids.map(&:model_id) }

      argument :milestone_wildcard_id, ::Types::MilestoneWildcardIdEnum,
        required: false,
        description: 'Filter by milestone ID wildcard.'

      validates mutually_exclusive: [:issue_types, :work_item_type_ids]
    end
  end
end

Types::Boards::BoardIssueInputBaseType.prepend_mod_with('Types::Boards::BoardIssueInputBaseType')
