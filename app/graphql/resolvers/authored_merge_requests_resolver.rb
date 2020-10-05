# frozen_string_literal: true

module Resolvers
  class AuthoredMergeRequestsResolver < UserMergeRequestsResolver
    accept_assignee

    def user_role
      :author
    end
  end
end
