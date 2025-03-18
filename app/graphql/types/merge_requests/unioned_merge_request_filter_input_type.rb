# frozen_string_literal: true

module Types
  module MergeRequests
    class UnionedMergeRequestFilterInputType < BaseInputObject
      graphql_name 'UnionedMergeRequestFilterInput'

      argument :assignee_usernames, [GraphQL::Types::String],
        required: false,
        description: 'Filters MRs that are assigned to at least one of the given users.'
    end
  end
end
