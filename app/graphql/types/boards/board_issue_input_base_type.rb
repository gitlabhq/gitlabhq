# frozen_string_literal: true

module Types
  module Boards
    # rubocop: disable Graphql/AuthorizeTypes
    class BoardIssueInputBaseType < BoardIssuableInputBaseType
      argument :iids, [GraphQL::STRING_TYPE],
               required: false,
               description: 'List of IIDs of issues. For example `["1", "2"]`.'

      argument :milestone_title, GraphQL::STRING_TYPE,
               required: false,
               description: 'Filter by milestone title.'

      argument :assignee_username, [GraphQL::STRING_TYPE, null: true],
               required: false,
               description: 'Filter by assignee username.'

      argument :release_tag, GraphQL::STRING_TYPE,
               required: false,
               description: 'Filter by release tag.'
    end
  end
end

Types::Boards::BoardIssueInputBaseType.prepend_mod_with('Types::Boards::BoardIssueInputBaseType')
