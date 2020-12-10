# frozen_string_literal: true

module Resolvers
  class AuthoredMergeRequestsResolver < UserMergeRequestsResolverBase
    type ::Types::MergeRequestType.connection_type, null: true
    accept_assignee
    accept_reviewer

    def user_role
      :author
    end
  end
end
