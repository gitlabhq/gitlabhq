# frozen_string_literal: true

module Types
  class IssueStateEnum < IssuableStateEnum
    graphql_name 'IssueState'
    description 'State of a GitLab issue'
  end
end
