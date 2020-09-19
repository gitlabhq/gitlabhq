# frozen_string_literal: true

module Types
  module Boards
    # rubocop: disable Graphql/AuthorizeTypes
    class NegatedBoardIssueInputType < BoardIssueInputBaseType
    end

    class BoardIssueInputType < BoardIssueInputBaseType
      graphql_name 'BoardIssueInput'

      argument :not, NegatedBoardIssueInputType,
               required: false,
               description: 'List of negated params. Warning: this argument is experimental and a subject to change in future'

      argument :search, GraphQL::STRING_TYPE,
               required: false,
               description: 'Search query for issue title or description'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end

Types::Boards::BoardIssueInputType.prepend_if_ee('::EE::Types::Boards::BoardIssueInputType')
