# frozen_string_literal: true

module Gitlab
  class CodeNavigationPath
    include Gitlab::Utils::StrongMemoize
    include Gitlab::Routing

    LATEST_COMMITS_LIMIT = 2
    ARTIFACT_TIMEOUT = 10.seconds

    def initialize(project, commit_sha)
      @project = project
      @commit_sha = commit_sha
    end

    def full_json_path_for(path)
      with_circuit_breaker do
        break unless build

        raw_project_job_artifacts_path(project, build, path: "lsif/#{path}.json", file_type: :lsif)
      end
    end

    private

    attr_reader :project, :commit_sha

    def with_circuit_breaker
      Gitlab::CircuitBreaker.run_with_circuit('CodeNavigationPath', circuit_breaker_options) do
        yield
      rescue Timeout::Error
        raise Gitlab::CircuitBreaker::InternalServerError
      end
    end

    # Disable CodeNavigation feature for 24 hours after several timeouts caused by a slow SQL query
    def circuit_breaker_options
      {
        sleep_window: 24.hours,
        time_window: 10.minutes,
        volume_threshold: 5
      }
    end

    def build
      strong_memoize(:build) do
        latest_commits_shas =
          project.repository.commits(commit_sha, limit: LATEST_COMMITS_LIMIT).map(&:sha)

        pipeline = @project.ci_pipelines.for_sha(latest_commits_shas).last

        next unless pipeline

        artifact = Timeout.timeout(ARTIFACT_TIMEOUT) do
          pipeline.job_artifacts.with_file_types(['lsif']).last
        end

        artifact&.job
      end
    end
  end
end
