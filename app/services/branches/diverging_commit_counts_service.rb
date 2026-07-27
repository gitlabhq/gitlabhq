# frozen_string_literal: true

module Branches
  class DivergingCommitCountsService
    def initialize(repository)
      @repository = repository
      @cache = Gitlab::RepositoryCache.new(repository)
    end

    def call(branch)
      @root_ref_sha ||= raw_repository.commit(repository.root_ref).id
      cache.fetch(:"diverging_commit_counts_#{branch.name}") do
        diverging_counts(@root_ref_sha, branch.target)
      end
    end

    def diverging_counts(from, to, max_count: 0)
      behind, ahead = raw_repository.diverging_commit_count(from, to, max_count: max_count)

      { behind: behind, ahead: ahead }
    end

    private

    attr_reader :repository, :cache

    delegate :raw_repository, to: :repository
  end
end
