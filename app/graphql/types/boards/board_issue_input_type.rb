# frozen_string_literal: true

module Types
  module Boards
    class NegatedBoardIssueInputType < BoardIssueInputBaseType
    end

    class BoardIssueInputType < BoardIssueInputBaseType
      graphql_name 'BoardIssueInput'

      argument :not, NegatedBoardIssueInputType,
               required: false,
               description: <<~MD
                 List of negated arguments.
                 Warning: this argument is experimental and a subject to change in future.
               MD

      argument :search, GraphQL::STRING_TYPE,
               required: false,
               description: 'Search query for issue title or description.'

      argument :assignee_wildcard_id, ::Types::Boards::AssigneeWildcardIdEnum,
               required: false,
               description: 'Filter by assignee wildcard. Incompatible with assigneeUsername.'
    end
  end
end

Types::Boards::BoardIssueInputType.prepend_if_ee('::EE::Types::Boards::BoardIssueInputType')
