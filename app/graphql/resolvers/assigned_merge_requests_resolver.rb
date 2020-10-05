# frozen_string_literal: true

module Resolvers
  class AssignedMergeRequestsResolver < UserMergeRequestsResolver
    accept_author

    def user_role
      :assignee
    end
  end
end
