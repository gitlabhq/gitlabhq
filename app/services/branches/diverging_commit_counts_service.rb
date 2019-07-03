# frozen_string_literal: true

module Branches
  class DivergingCommitCountsService
    def initialize(repository)
      @repository = repository
      @cache = Gitlab::RepositoryCache.new(repository)
    end

    def call(branch)
      if Feature.enabled?('gitaly_count_diverging_commits_no_max')
        diverging_commit_counts_without_max(branch)
      else
        diverging_commit_counts(branch)
      end
    end

    private

    attr_reader :repository, :cache

    delegate :raw_repository, to: :repository

    def diverging_commit_counts(branch)
      ## TODO: deprecate the below code after 12.0
      @root_ref_hash ||= raw_repository.commit(repository.root_ref).id
      cache.fetch(:"diverging_commit_counts_#{branch.name}") do
        number_commits_behind, number_commits_ahead =
          repository.raw_repository.diverging_commit_count(
            @root_ref_hash,
            branch.dereferenced_target.sha,
            max_count: Repository::MAX_DIVERGING_COUNT)

        if number_commits_behind + number_commits_ahead >= Repository::MAX_DIVERGING_COUNT
          { distance: Repository::MAX_DIVERGING_COUNT }
        else
          { behind: number_commits_behind, ahead: number_commits_ahead }
        end
      end
    end

    def diverging_commit_counts_without_max(branch)
      @root_ref_hash ||= raw_repository.commit(repository.root_ref).id
      cache.fetch(:"diverging_commit_counts_without_max_#{branch.name}") do
        number_commits_behind, number_commits_ahead =
          raw_repository.diverging_commit_count(
            @root_ref_hash,
            branch.dereferenced_target.sha)

        { behind: number_commits_behind, ahead: number_commits_ahead }
      end
    end
  end
end
