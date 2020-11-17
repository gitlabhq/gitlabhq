# frozen_string_literal: true

module Resolvers
  class ProjectMergeRequestsResolver < MergeRequestsResolver
    type ::Types::MergeRequestType.connection_type, null: true
    accept_assignee
    accept_author
  end
end
