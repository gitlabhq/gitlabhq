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
      ref_sha_pairs = refs.map { |ref| [ref.name, ref.dereferenced_target.sha] }
      pipelines.latest_pipeline_per_ref(ref_sha_pairs)
    end

    attr_reader :project, :repository, :current_user, :refs, :ref_type
  end
end
