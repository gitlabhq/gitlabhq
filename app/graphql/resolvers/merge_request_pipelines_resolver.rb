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
      finder = ::Ci::PipelinesForMergeRequestFinder.new(mr, current_user)

      # Fork MRs can have pipelines in the target project too, so the finder's
      # project scope is removed. `merge` must follow `unscope` - it re-adds
      # the per-project `for_project` filter that `execute` uses to enforce
      # `read_pipeline` on each project. Reversed, that filter is stripped.
      resolve_pipelines(finder.authorizing_project, args.merge(merge_request_event_first: true))
        .unscope(where: :project_id) # rubocop:disable CodeReuse/ActiveRecord -- removes Ci::PipelinesFinder's project scoping
        .merge(finder.execute)
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
