# frozen_string_literal: true

module Ci
  # Extends pipeline reference filtering to include reserved ref names
  # associated with merge requests that use the given ref as source branch.
  module PipelineRefFilterIncludingReservedRefNames
    MERGE_REQUEST_LIMIT = 100
    NAMESPACE_BATCH_SIZE = 100
    PROJECT_BATCH_SIZE = 500

    # Returns an array containing the original ref and any associated reserved refs
    # from merge requests that use the given ref as source branch.
    #
    # @param container [Namespace, Project] The container used for requests
    # @param ref [String, nil] The git reference to filter by
    # @param pipeline_sources [Array<String>, String, nil] The pipeline sources to consider
    # @return [Array<String>] Array of refs including the original and any reserved refs
    def ref_and_associated_reserved_refs(container, ref, pipeline_sources = nil)
      return [ref] unless ref && Feature.enabled?(:include_reserved_refs_in_pipeline_refs_filter, actor(container))

      normalized_sources = Array.wrap(pipeline_sources || Pipeline.sources.keys).map(&:to_s)

      if normalized_sources.include?('merge_request_event')
        [ref, *merge_request_reserved_refs_for_container(container, ref)]
      else
        [ref]
      end
    end

    private

    def merge_request_reserved_refs_for_container(container, ref)
      query = ::MergeRequest.from_source_branches(ref)

      case container
      when Project
        merge_request_reserved_refs_for_projects(query, container)
      when Namespace
        merge_request_reserved_refs_for_group(query, container)
      else
        raise ArgumentError, "#{container.inspect} is not a valid container"
      end
    end

    def merge_request_reserved_refs_for_projects(merge_requests_query, projects)
      merge_requests_query
        .from_project(projects)
        .limit(MERGE_REQUEST_LIMIT)
        .select(:iid)
        .flat_map { |mr| [mr.ref_path, mr.merge_ref_path, mr.train_ref_path] }
    end

    def merge_request_reserved_refs_for_group(query, group)
      refs = []
      cursor = { current_id: group.id, depth: [group.id] }
      iterator = Gitlab::Database::NamespaceEachBatch.new(namespace_class: Namespace, cursor: cursor)

      iterator.each_batch(of: NAMESPACE_BATCH_SIZE) do |ids, _new_cursor|
        Project.in_namespace(ids).each_batch(of: PROJECT_BATCH_SIZE) do |project_batch|
          refs.concat(merge_request_reserved_refs_for_projects(query, project_batch))
        end
      end

      refs
    end

    def actor(container)
      return container.parent if container.is_a?(Project)

      container
    end
  end
end
