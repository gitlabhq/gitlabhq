# frozen_string_literal: true

module Releases
  class EvidencePipelineFinder
    include Gitlab::Utils::StrongMemoize

    attr_reader :project, :params

    def initialize(project, params = {})
      @project = project
      @params = params
    end

    def execute
      # TODO: remove this with the release creation moved to it's own form https://gitlab.com/gitlab-org/gitlab/-/issues/214245
      return params[:evidence_pipeline] if params[:evidence_pipeline]

      sha = existing_tag&.dereferenced_target&.sha
      sha ||= repository&.commit(ref)&.sha

      return unless sha

      project.ci_pipelines.for_sha(sha).last
    end

    private

    def repository
      strong_memoize(:repository) do
        project.repository
      end
    end

    def existing_tag
      repository.find_tag(tag_name)
    end

    def tag_name
      params[:tag]
    end

    def ref
      params[:ref]
    end
  end
end
