# frozen_string_literal: true

module Ci
  class CommitStatusesFinder
    include ::Gitlab::Utils::StrongMemoize

    def initialize(project, repository, current_user, refs, ref_type: nil)
      @project = project
      @repository = repository
      @current_user = current_user
      @refs = refs
      @ref_type = ref_type
    end

    def execute
      return {} unless Ability.allowed?(@current_user, :read_pipeline, @project)

      pipelines.to_h do |pipeline|
        [pipeline.ref, pipeline.detailed_status(current_user)]
      end
    end

    private

    def pipelines
      project.ci_pipelines.then do |pipelines|
        case ref_type
        when :tags then latest_pipeline_per_ref(pipelines.tag)
        when :heads then latest_pipeline_per_ref(pipelines.no_tag)
        else latest_pipeline_per_ref(pipelines)
        end
      end
    end

    def latest_pipeline_per_ref(pipelines)
      if Feature.enabled?(:branches_page_pipeline_lookup_by_sha, project)
        # Implied by the (ref, sha) join, but lets PostgreSQL use the (project_id, sha) index.
        pipelines = pipelines.for_sha(ref_sha_pairs.map(&:last).uniq)
      end

      pipelines.latest_pipeline_per_ref(ref_sha_pairs)
    end

    def ref_sha_pairs
      refs.filter_map { |ref| [ref.name, ref.dereferenced_target.sha] if ref.dereferenced_target }
    end
    strong_memoize_attr :ref_sha_pairs

    attr_reader :project, :repository, :current_user, :refs, :ref_type
  end
end
