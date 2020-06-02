# frozen_string_literal: true

module Resolvers
  class AuthoredMergeRequestsResolver < UserMergeRequestsResolver
    def user_role
      :author
    end
  end
end
