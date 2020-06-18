# frozen_string_literal: true

module Resolvers
  class MergeRequestsResolver < BaseResolver
    include ResolvesMergeRequests

    alias_method :project, :synchronized_object

    argument :iids, [GraphQL::STRING_TYPE],
              required: false,
              description: 'Array of IIDs of merge requests, for example `[1, 2]`'

    argument :source_branches, [GraphQL::STRING_TYPE],
             required: false,
             as: :source_branch,
             description: 'Array of source branch names. All resolved merge requests will have one of these branches as their source.'

    argument :target_branches, [GraphQL::STRING_TYPE],
             required: false,
             as: :target_branch,
             description: 'Array of target branch names. All resolved merge requests will have one of these branches as their target.'

    argument :state, ::Types::MergeRequestStateEnum,
             required: false,
             description: 'A merge request state. If provided, all resolved merge requests will have this state.'

    argument :labels, [GraphQL::STRING_TYPE],
             required: false,
             as: :label_name,
             description: 'Array of label names. All resolved merge requests will have all of these labels.'

    def self.single
      ::Resolvers::MergeRequestResolver
    end

    def no_results_possible?(args)
      project.nil? || some_argument_is_empty?(args)
    end

    def some_argument_is_empty?(args)
      args.values.any? { |v| v.is_a?(Array) && v.empty? }
    end
  end
end
