module Projects
  # Service class for counting and caching the number of open issues of a
  # project.
  class OpenIssuesCountService < Projects::CountService
    include Gitlab::Utils::StrongMemoize

    def initialize(project, user = nil)
      @user = user

      super(project)
    end

    def cache_key_name
      public_only? ? 'public_open_issues_count' : 'total_open_issues_count'
    end

    def public_only?
      !user_is_at_least_reporter?
    end

    def relation_for_count
      self.class.query(@project, public_only: public_only?)
    end

    def user_is_at_least_reporter?
      strong_memoize(:user_is_at_least_reporter) do
        @user && @project.team.member?(@user, Gitlab::Access::REPORTER)
      end
    end

    # We only show total issues count for reporters
    # which are allowed to view confidential issues
    # This will still show a discrepancy on issues number but should be less than before.
    # Check https://gitlab.com/gitlab-org/gitlab-ce/issues/38418 description.
    def self.query(projects, public_only: true)
      if public_only
        Issue.opened.public_only.where(project: projects)
      else
        Issue.opened.where(project: projects)
      end
    end
  end
end
