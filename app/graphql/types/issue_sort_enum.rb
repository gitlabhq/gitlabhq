# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class IssueSortEnum < IssuableSortEnum
    graphql_name 'IssueSort'
    description 'Values for sorting issues'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
