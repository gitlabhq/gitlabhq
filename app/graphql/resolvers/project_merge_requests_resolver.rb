# frozen_string_literal: true

module Resolvers
  class ProjectMergeRequestsResolver < MergeRequestsResolver
    argument :assignee_username, GraphQL::STRING_TYPE,
             required: false,
             description: 'Username of the assignee'
    argument :author_username, GraphQL::STRING_TYPE,
             required: false,
             description: 'Username of the author'
  end
end
