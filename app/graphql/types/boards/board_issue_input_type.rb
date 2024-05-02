# frozen_string_literal: true

module Types
  module Boards
    class BoardIssueInputType < BoardIssueInputBaseType
      graphql_name 'BoardIssueInput'

      argument :not, NegatedBoardIssueInputType,
        required: false,
        description: 'List of negated arguments.'

      argument :or, Types::Issues::UnionedIssueFilterInputType,
        required: false,
        description: 'List of arguments with inclusive OR.'

      argument :search, GraphQL::Types::String,
        required: false,
        description: 'Search query for issue title or description.'

      argument :assignee_wildcard_id, ::Types::AssigneeWildcardIdEnum,
        required: false,
        description: 'Filter by assignee wildcard. Incompatible with assigneeUsername and assigneeUsernames.'

      argument :confidential, GraphQL::Types::Boolean,
        required: false,
        description: 'Filter by confidentiality.'
    end
  end
end

Types::Boards::BoardIssueInputType.prepend_mod_with('Types::Boards::BoardIssueInputType')
