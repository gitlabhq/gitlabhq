# frozen_string_literal: true

module Resolvers
  class AssignedMergeRequestsResolver < UserMergeRequestsResolverBase
    type ::Types::MergeRequestType.connection_type, null: true
    accept_author

    def user_role
      :assignee
    end
  end
end
