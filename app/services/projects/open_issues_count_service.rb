# frozen_string_literal: true

module Projects
  # Service class for counting and caching the number of open issues of a
  # project.
  class OpenIssuesCountService < Projects::CountService
    include Gitlab::Utils::StrongMemoize

    # Cache keys used to store issues count
    PUBLIC_COUNT_KEY = 'public_open_issues_count'
    TOTAL_COUNT_KEY = 'total_open_issues_count'

    def initialize(project, user = nil)
      @user = user

      super(project)
    end

    def cache_key_name
      public_only? ? PUBLIC_COUNT_KEY : TOTAL_COUNT_KEY
    end

    def public_only?
      !user_is_at_least_planner?
    end

    def user_is_at_least_planner?
      strong_memoize(:user_is_at_least_planner) do
        @project.member?(@user, Gitlab::Access::PLANNER)
      end
    end

    def relation_for_count
      self.class.query(@project, public_only: public_only?)
    end

    def public_count_cache_key
      cache_key(PUBLIC_COUNT_KEY)
    end

    def total_count_cache_key
      cache_key(TOTAL_COUNT_KEY)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def refresh_cache(&block)
      count_grouped_by_confidential = self.class.query(@project, public_only: false).group(:confidential).count
      public_count = count_grouped_by_confidential[false] || 0
      total_count = public_count + (count_grouped_by_confidential[true] || 0)

      update_cache_for_key(public_count_cache_key) do
        public_count
      end

      update_cache_for_key(total_count_cache_key) do
        total_count
      end
    end

    # We only show issues count including confidential for planners, who are allowed to view confidential issues.
    # This will still show a discrepancy on issues number but should be less than before.
    # Check https://gitlab.com/gitlab-org/gitlab-foss/issues/38418 description.

    def self.query(projects, public_only: true)
      open_issues = Issue.opened.without_hidden

      if public_only
        open_issues.public_only.where(project: projects)
      else
        open_issues.where(project: projects)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
