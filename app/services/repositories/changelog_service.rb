# frozen_string_literal: true

module Repositories
  # A service class for generating a changelog section.
  class ChangelogService
    DEFAULT_TRAILER = 'Changelog'
    DEFAULT_FILE = 'CHANGELOG.md'

    # The `project` specifies the `Project` to generate the changelog section
    # for.
    #
    # The `user` argument specifies a `User` to use for committing the changes
    # to the Git repository.
    #
    # The `version` arguments must be a version `String` using semantic
    # versioning as the format.
    #
    # The arguments `from` and `to` must specify a Git ref or SHA to use for
    # fetching the commits to include in the changelog. The SHA/ref set in the
    # `from` argument isn't included in the list.
    #
    # The `date` argument specifies the date of the release, and defaults to the
    # current time/date.
    #
    # The `branch` argument specifies the branch to commit the changes to. The
    # branch must already exist.
    #
    # The `trailer` argument is the Git trailer to use for determining what
    # commits to include in the changelog.
    #
    # The `file` arguments specifies the name/path of the file to commit the
    # changes to. If the file doesn't exist, it's created automatically.
    #
    # The `message` argument specifies the commit message to use when committing
    # the changelog changes.
    #
    # rubocop: disable Metrics/ParameterLists
    def initialize(
      project,
      user,
      version:,
      branch: project.default_branch_or_main,
      from: nil,
      to: branch,
      date: DateTime.now,
      trailer: DEFAULT_TRAILER,
      file: DEFAULT_FILE,
      message: "Add changelog for version #{version}"
    )
      @project = project
      @user = user
      @version = version
      @from = from
      @to = to
      @date = date
      @branch = branch
      @trailer = trailer
      @file = file
      @message = message
    end
    # rubocop: enable Metrics/ParameterLists

    def execute
      config = Gitlab::Changelog::Config.from_git(@project)
      from = start_of_commit_range(config)

      # For every entry we want to only include the merge request that
      # originally introduced the commit, which is the oldest merge request that
      # contains the commit. We fetch there merge requests in batches, reducing
      # the number of SQL queries needed to get this data.
      mrs_finder = MergeRequests::OldestPerCommitFinder.new(@project)
      release = Gitlab::Changelog::Release
        .new(version: @version, date: @date, config: config)

      commits =
        ChangelogCommitsFinder.new(project: @project, from: from, to: @to)

      commits.each_page(@trailer) do |page|
        mrs = mrs_finder.execute(page)

        # Preload the authors. This ensures we only need a single SQL query per
        # batch of commits, instead of needing a query for every commit.
        page.each(&:lazy_author)

        page.each do |commit|
          release.add_entry(
            title: commit.title,
            commit: commit,
            category: commit.trailers.fetch(@trailer),
            author: commit.author,
            merge_request: mrs[commit.id]
          )
        end
      end

      Gitlab::Changelog::Committer
        .new(@project, @user)
        .commit(release: release, file: @file, branch: @branch, message: @message)
    end

    def start_of_commit_range(config)
      return @from if @from

      finder = ChangelogTagFinder.new(@project, regex: config.tag_regex)

      if (prev_tag = finder.execute(@version))
        return prev_tag.target_commit.id
      end

      raise(
        Gitlab::Changelog::Error,
        'The commit start range is unspecified, and no previous tag ' \
          'could be found to use instead'
      )
    end
  end
end
