# frozen_string_literal: true

module Resolvers
  class AuthoredMergeRequestsResolver < UserMergeRequestsResolverBase
    type ::Types::MergeRequestType.connection_type, null: true
    accept_assignee
    accept_reviewer

    argument :include_assigned, GraphQL::Types::Boolean,
      required: false,
      default_value: false,
      description: "Include merge requests the user is assigned to."

    def user_role
      :author
    end
  end
end
