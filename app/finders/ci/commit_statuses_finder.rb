# frozen_string_literal: true

module Ci
  class CommitStatusesFinder
    include ::Gitlab::Utils::StrongMemoize

    def initialize(project, repository, current_user, refs)
      @project = project
      @repository = repository
      @current_user = current_user
      @refs = refs
    end

    def execute
      return {} unless Ability.allowed?(@current_user, :read_pipeline, @project)

      commit_statuses
    end

    private

    def latest_commits
      strong_memoize(:latest_commits) do
        refs.to_h do |ref|
          [ref.name, @repository.commit(ref.dereferenced_target).sha]
        end
      end
    end

    def commit_statuses
      latest_pipelines = project.ci_pipelines.latest_pipeline_per_commit(latest_commits.values)

      latest_commits.transform_values do |commit_sha|
        latest_pipelines[commit_sha]&.detailed_status(current_user)
      end.compact
    end

    attr_reader :project, :repository, :current_user, :refs
  end
end
