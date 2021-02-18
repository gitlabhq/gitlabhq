# frozen_string_literal: true

module Repositories
  # Finder for obtaining commits between two refs, with a Git trailer set.
  class CommitsWithTrailerFinder
    # The maximum number of commits to retrieve per page.
    #
    # This value is arbitrarily chosen. Lowering it means more Gitaly calls, but
    # less data being loaded into memory at once. Increasing it has the opposite
    # effect.
    #
    # This amount is based around the number of commits that usually go in a
    # GitLab release. Some examples for GitLab's own releases:
    #
    # * 13.6.0: 4636 commits
    # * 13.5.0: 5912 commits
    # * 13.4.0: 5541 commits
    #
    # Using this limit should result in most (very large) projects only needing
    # 5-10 Gitaly calls, while keeping memory usage at a reasonable amount.
    COMMITS_PER_PAGE = 1024

    # The `project` argument specifies the project for which to obtain the
    # commits.
    #
    # The `from` and `to` arguments specify the range of commits to include. The
    # commit specified in `from` won't be included itself. The commit specified
    # in `to` _is_ included.
    #
    # The `per_page` argument specifies how many commits are retrieved in a single
    # Gitaly API call.
    def initialize(project:, from:, to:, per_page: COMMITS_PER_PAGE)
      @project = project
      @from = from
      @to = to
      @per_page = per_page
    end

    # Fetches all commits that have the given trailer set.
    #
    # The commits are yielded to the supplied block in batches. This allows
    # other code to process these commits in batches too, instead of first
    # having to load all commits into memory.
    #
    # Example:
    #
    #     CommitsWithTrailerFinder.new(...).each_page('Signed-off-by') do |commits|
    #       commits.each do |commit|
    #         ...
    #       end
    #     end
    def each_page(trailer)
      return to_enum(__method__, trailer) unless block_given?

      offset = 0
      response = fetch_commits

      while response.any?
        commits = []

        response.each do |commit|
          commits.push(commit) if commit.trailers.key?(trailer)
        end

        yield commits

        offset += response.length
        response = fetch_commits(offset)
      end
    end

    private

    def fetch_commits(offset = 0)
      range = "#{@from}..#{@to}"

      @project
        .repository
        .commits(range, limit: @per_page, offset: offset, trailers: true)
    end
  end
end
