# frozen_string_literal: true

module Repositories
  # A service class for generating a changelog section.
  class ChangelogService
    DEFAULT_TRAILER = 'Changelog'
    DEFAULT_FILE = 'CHANGELOG.md'

    # The maximum number of commits allowed to fetch in `from` and `to` range.
    #
    # This value is arbitrarily chosen. Increasing it means more Gitaly calls
    # and more presure on Gitaly services.
    #
    # This number is 3x of the average number of commits per GitLab releases.
    # Some examples for GitLab's own releases:
    #
    # * 13.6.0: 4636 commits
    # * 13.5.0: 5912 commits
    # * 13.4.0: 5541 commits
    COMMITS_LIMIT = 15_000

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
    # The `config_file` arguments specifies the path to the configuration file as
    # stored in the project's Git repository.
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
      config_file: Gitlab::Changelog::Config::DEFAULT_FILE_PATH,
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
      @config_file = config_file
      @file = file
      @message = message
    end
    # rubocop: enable Metrics/ParameterLists

    def execute(commit_to_changelog: true)
      config = Gitlab::Changelog::Config.from_git(@project, @user, @config_file)
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

      verify_commit_range!(from, @to)

      commits.each_page(@trailer) do |page|
        mrs = mrs_finder.execute(page)

        # Preload the authors. This ensures we only need a single SQL query per
        # batch of commits, instead of needing a query for every commit.
        page.each(&:lazy_author)

        # Preload author permissions
        @project.team.max_member_access_for_user_ids(page.map(&:author).compact.map(&:id))

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

      if commit_to_changelog
        Gitlab::Changelog::Committer
          .new(@project, @user)
          .commit(release: release, file: @file, branch: @branch, message: @message)
      else
        Gitlab::Changelog::Generator.new.add(release)
      end
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

    def verify_commit_range!(from, to)
      commits = @project.repository.commits_by(oids: [from, to])

      raise Gitlab::Changelog::Error, "Invalid or not found commit value in the given range" unless commits.count == 2

      _, commits_count = @project.repository.diverging_commit_count(from, to)

      if commits_count > COMMITS_LIMIT
        raise Gitlab::Changelog::Error, "The commits range exceeds #{COMMITS_LIMIT} elements."
      end
    end
  end
end
