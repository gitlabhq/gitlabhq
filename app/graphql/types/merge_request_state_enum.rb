# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  # This is a BaseEnum through IssuableEnum, so it does not need authorization
  class MergeRequestStateEnum < IssuableStateEnum
    graphql_name 'MergeRequestState'
    description 'State of a GitLab merge request'

    value 'merged'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
