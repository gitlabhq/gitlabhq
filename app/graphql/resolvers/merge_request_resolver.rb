# frozen_string_literal: true

module Resolvers
  class MergeRequestResolver < BaseResolver.single
    include ResolvesMergeRequests

    alias_method :project, :synchronized_object

    argument :iid, GraphQL::STRING_TYPE,
              required: true,
              as: :iids,
              description: 'IID of the merge request, for example `1`'

    def no_results_possible?(args)
      project.nil?
    end
  end
end
