# frozen_string_literal: true

module Resolvers
  class MergeRequestsResolver < BaseResolver
    include ResolvesMergeRequests
    extend ::Gitlab::Graphql::NegatableArguments

    type ::Types::MergeRequestType.connection_type, null: true

    alias_method :project, :object

    def self.accept_assignee
      argument :assignee_username, GraphQL::Types::String,
               required: false,
               description: 'Username of the assignee.'
    end

    def self.accept_author
      argument :author_username, GraphQL::Types::String,
               required: false,
               description: 'Username of the author.'
    end

    def self.accept_reviewer
      argument :reviewer_username, GraphQL::Types::String,
               required: false,
               description: 'Username of the reviewer.'
    end

    argument :iids, [GraphQL::Types::String],
             required: false,
             description: 'Array of IIDs of merge requests, for example `[1, 2]`.'

    argument :source_branches, [GraphQL::Types::String],
             required: false,
             as: :source_branch,
             description: <<~DESC
               Array of source branch names.
               All resolved merge requests will have one of these branches as their source.
             DESC

    argument :target_branches, [GraphQL::Types::String],
             required: false,
             as: :target_branch,
             description: <<~DESC
               Array of target branch names.
               All resolved merge requests will have one of these branches as their target.
             DESC

    argument :state, ::Types::MergeRequestStateEnum,
             required: false,
             description: 'A merge request state. If provided, all resolved merge requests will have this state.'

    argument :labels, [GraphQL::Types::String],
             required: false,
             as: :label_name,
             description: 'Array of label names. All resolved merge requests will have all of these labels.'
    argument :merged_after, Types::TimeType,
             required: false,
             description: 'Merge requests merged after this date.'
    argument :merged_before, Types::TimeType,
             required: false,
             description: 'Merge requests merged before this date.'
    argument :milestone_title, GraphQL::Types::String,
             required: false,
             description: 'Title of the milestone.'
    argument :sort, Types::MergeRequestSortEnum,
             description: 'Sort merge requests by this criteria.',
             required: false,
             default_value: :created_desc

    negated do
      argument :labels, [GraphQL::Types::String],
               required: false,
               as: :label_name,
               description: 'Array of label names. All resolved merge requests will not have these labels.'
      argument :milestone_title, GraphQL::Types::String,
               required: false,
               description: 'Title of the milestone.'
    end

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
