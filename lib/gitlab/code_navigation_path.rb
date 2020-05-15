# frozen_string_literal: true

module Gitlab
  class CodeNavigationPath
    include Gitlab::Utils::StrongMemoize
    include Gitlab::Routing

    LATEST_COMMITS_LIMIT = 10

    def initialize(project, commit_sha)
      @project = project
      @commit_sha = commit_sha
    end

    def full_json_path_for(path)
      return if Feature.disabled?(:code_navigation, project)
      return unless build

      raw_project_job_artifacts_path(project, build, path: "lsif/#{path}.json", file_type: :lsif)
    end

    private

    attr_reader :project, :commit_sha

    def build
      strong_memoize(:build) do
        latest_commits_shas =
          project.repository.commits(commit_sha, limit: LATEST_COMMITS_LIMIT).map(&:sha)

        artifact =
          ::Ci::JobArtifact
            .with_file_types(['lsif'])
            .for_sha(latest_commits_shas, project.id)
            .last

        artifact&.job
      end
    end
  end
end
