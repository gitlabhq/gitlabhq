# frozen_string_literal: true

module Resolvers
  class AssignedMergeRequestsResolver < UserMergeRequestsResolver
    def user_role
      :assignee
    end
  end
end
