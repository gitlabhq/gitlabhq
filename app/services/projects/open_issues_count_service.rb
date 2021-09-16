# frozen_string_literal: true

module Projects
  # Service class for counting and caching the number of open issues of a
  # project.
  class OpenIssuesCountService < Projects::CountService
    include Gitlab::Utils::StrongMemoize

    # Cache keys used to store issues count
    # TOTAL_COUNT_KEY includes confidential and hidden issues (admin)
    # TOTAL_COUNT_WITHOUT_HIDDEN_KEY includes confidential issues but not hidden issues (reporter and above)
    # PUBLIC_COUNT_WITHOUT_HIDDEN_KEY does not include confidential or hidden issues (guest)
    TOTAL_COUNT_KEY = 'project_open_issues_including_hidden_count'
    TOTAL_COUNT_WITHOUT_HIDDEN_KEY = 'project_open_issues_without_hidden_count'
    PUBLIC_COUNT_WITHOUT_HIDDEN_KEY = 'project_open_public_issues_without_hidden_count'

    def initialize(project, user = nil)
      @user = user

      super(project)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def refresh_cache(&block)
      if block_given?
        super(&block)
      else
        update_cache_for_key(total_count_cache_key) do
          issues_with_hidden
        end

        update_cache_for_key(public_count_without_hidden_cache_key) do
          issues_without_hidden_without_confidential
        end

        update_cache_for_key(total_count_without_hidden_cache_key) do
          issues_without_hidden_with_confidential
        end
      end
    end

    private

    def relation_for_count
      self.class.query(@project, public_only: public_only?, include_hidden: include_hidden?)
    end

    def cache_key_name
      if include_hidden?
        TOTAL_COUNT_KEY
      elsif public_only?
        PUBLIC_COUNT_WITHOUT_HIDDEN_KEY
      else
        TOTAL_COUNT_WITHOUT_HIDDEN_KEY
      end
    end

    def include_hidden?
      user_is_admin?
    end

    def public_only?
      !user_is_at_least_reporter?
    end

    def user_is_admin?
      strong_memoize(:user_is_admin) do
        @user&.can_admin_all_resources?
      end
    end

    def user_is_at_least_reporter?
      strong_memoize(:user_is_at_least_reporter) do
        @user && @project.team.member?(@user, Gitlab::Access::REPORTER)
      end
    end

    def total_count_without_hidden_cache_key
      cache_key(TOTAL_COUNT_WITHOUT_HIDDEN_KEY)
    end

    def public_count_without_hidden_cache_key
      cache_key(PUBLIC_COUNT_WITHOUT_HIDDEN_KEY)
    end

    def total_count_cache_key
      cache_key(TOTAL_COUNT_KEY)
    end

    def issues_with_hidden
      self.class.query(@project, public_only: false, include_hidden: true).count
    end

    def issues_without_hidden_without_confidential
      self.class.query(@project, public_only: true, include_hidden: false).count
    end

    def issues_without_hidden_with_confidential
      self.class.query(@project, public_only: false, include_hidden: false).count
    end

    # We only show total issues count for admins, who are allowed to view hidden issues.
    # We also only show issues count including confidential for reporters, who are allowed to view confidential issues.
    # This will still show a discrepancy on issues number but should be less than before.
    # Check https://gitlab.com/gitlab-org/gitlab-foss/issues/38418 description.
    # rubocop: disable CodeReuse/ActiveRecord

    def self.query(projects, public_only: true, include_hidden: false)
      if include_hidden
        Issue.opened.with_issue_type(Issue::TYPES_FOR_LIST).where(project: projects)
      elsif public_only
        Issue.public_only.opened.with_issue_type(Issue::TYPES_FOR_LIST).where(project: projects)
      else
        Issue.without_hidden.opened.with_issue_type(Issue::TYPES_FOR_LIST).where(project: projects)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
