# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  # This is a BaseEnum through IssuableEnum, so it does not need authorization
  class IssueStateEnum < IssuableStateEnum
    graphql_name 'IssueState'
    description 'State of a GitLab issue'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
