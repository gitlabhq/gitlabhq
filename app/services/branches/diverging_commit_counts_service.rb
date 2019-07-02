# frozen_string_literal: true

module Branches
  class DivergingCommitCountsService
    def initialize(repository)
      @repository = repository
      @cache = Gitlab::RepositoryCache.new(repository)
    end

    def call(branch)
      diverging_commit_counts(branch)
    end

    private

    attr_reader :repository, :cache

    delegate :raw_repository, to: :repository

    def diverging_commit_counts(branch)
      @root_ref_hash ||= raw_repository.commit(repository.root_ref).id
      cache.fetch(:"diverging_commit_counts_#{branch.name}") do
        number_commits_behind, number_commits_ahead =
          raw_repository.diverging_commit_count(
            @root_ref_hash,
            branch.dereferenced_target.sha)

        { behind: number_commits_behind, ahead: number_commits_ahead }
      end
    end
  end
end
