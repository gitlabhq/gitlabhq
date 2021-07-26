# frozen_string_literal: true

module Types
  module Boards
    class BoardIssueInputType < BoardIssueInputBaseType
      graphql_name 'BoardIssueInput'

      argument :not, NegatedBoardIssueInputType,
               required: false,
               prepare: ->(negated_args, ctx) { negated_args.to_h },
               description: 'List of negated arguments.'

      argument :search, GraphQL::Types::String,
               required: false,
               description: 'Search query for issue title or description.'

      argument :assignee_wildcard_id, ::Types::Boards::AssigneeWildcardIdEnum,
               required: false,
               description: 'Filter by assignee wildcard. Incompatible with assigneeUsername.'
    end
  end
end

Types::Boards::BoardIssueInputType.prepend_mod_with('Types::Boards::BoardIssueInputType')
