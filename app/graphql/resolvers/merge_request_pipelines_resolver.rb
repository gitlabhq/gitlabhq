# frozen_string_literal: true
# rubocop: disable Graphql/ResolverType

module Resolvers
  class MergeRequestPipelinesResolver < BaseResolver
    # The GraphQL type here gets defined in this include
    include ::ResolvesPipelines
    include ::CachingArrayResolver

    alias_method :merge_request, :object

    # Return at most 500 pipelines for each MR.
    # Merge requests generally have many fewer pipelines than this.
    def self.field_options
      super.merge(max_page_size: 500)
    end

    def resolve(**args)
      return unless project

      super
    end

    def query_for(args)
      resolve_pipelines(project, args).merge(merge_request.all_pipelines)
    end

    def model_class
      ::Ci::Pipeline
    end

    def query_input(**args)
      args
    end

    def project
      merge_request.source_project
    end
  end
end
# rubocop: enable Graphql/ResolverType
