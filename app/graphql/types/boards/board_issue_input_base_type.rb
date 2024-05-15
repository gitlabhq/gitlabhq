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

      argument :milestone_wildcard_id, ::Types::MilestoneWildcardIdEnum,
        required: false,
        description: 'Filter by milestone ID wildcard.'
    end
  end
end

Types::Boards::BoardIssueInputBaseType.prepend_mod_with('Types::Boards::BoardIssueInputBaseType')
