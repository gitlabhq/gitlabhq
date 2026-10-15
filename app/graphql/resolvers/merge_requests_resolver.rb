# frozen_string_literal: true

module Resolvers
  class MergeRequestsResolver < BaseResolver
    include ResolvesMergeRequests
    include SearchArguments
    include ::MergeRequests::SharedFilterArguments

    type ::Types::MergeRequestType.connection_type, null: true

    alias_method :project, :object

    argument :sort, Types::MergeRequestSortEnum,
      description: 'Sort merge requests by the criteria.',
      required: false,
      default_value: :created_desc

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
