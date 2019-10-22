# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class IssuableSortEnum < SortEnum
    graphql_name 'IssuableSort'
    description 'Values for sorting issuables'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
