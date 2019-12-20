# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  # Types that use DiffRefsType should have their own authorization
  class DiffRefsType < BaseObject
    graphql_name 'DiffRefs'

    field :head_sha, GraphQL::STRING_TYPE, null: false,
          description: 'SHA of the HEAD at the time the comment was made'
    field :base_sha, GraphQL::STRING_TYPE, null: false,
          description: 'Merge base of the branch the comment was made on'
    field :start_sha, GraphQL::STRING_TYPE, null: false,
          description: 'SHA of the branch being compared against'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
