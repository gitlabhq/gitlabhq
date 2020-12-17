# frozen_string_literal: true

module Resolvers
  class ReviewRequestedMergeRequestsResolver < UserMergeRequestsResolverBase
    type ::Types::MergeRequestType.connection_type, null: true
    accept_author
    accept_assignee

    def user_role
      :reviewer
    end
  end
end
