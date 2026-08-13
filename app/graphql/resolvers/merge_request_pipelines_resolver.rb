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
    max_page_size 500

    def resolve(**args)
      return unless project

      super
    end

    def query_for(input)
      mr, args = input
      # Both `resolve_pipelines` (via `Ci::PipelinesFinder`) and
      # `mr.all_pipelines` (via `Ci::PipelinesForMergeRequestFinder`) apply the
      # shared `Ci::Pipeline.merge_request_event_first` scope, so the MR
      # Pipelines tab surfaces `merge_request_event`-sourced pipelines first,
      # matching the legacy REST-based path. Because both relations carry the
      # identical order values, ActiveRecord's `merge` de-duplicates them and
      # the generated SQL contains the ORDER BY clause once.
      resolve_pipelines(mr.source_project, args.merge(merge_request_event_first: true))
        .merge(mr.all_pipelines)
    end

    def model_class
      ::Ci::Pipeline
    end

    def query_input(**args)
      [merge_request, args]
    end

    def project
      merge_request.source_project
    end
  end
end
# rubocop: enable Graphql/ResolverType
