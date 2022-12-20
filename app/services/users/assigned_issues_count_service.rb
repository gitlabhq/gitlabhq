# frozen_string_literal: true

module Users
  class AssignedIssuesCountService < ::BaseCountService
    def initialize(current_user:, max_limit: User::MAX_LIMIT_FOR_ASSIGNEED_ISSUES_COUNT)
      @current_user = current_user
      @max_limit = max_limit
    end

    def cache_key
      ['users', @current_user.id, 'max_assigned_open_issues_count']
    end

    def cache_options
      { force: false, expires_in: User::COUNT_CACHE_VALIDITY_PERIOD }
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def uncached_count
      # When a user has many assigned issues, counting them all can be very slow.
      # As a workaround, we will short-circuit the counting query once the count reaches some threshold.
      #
      # Concretely, given a threshold, say 100 (= max_limit),
      # iterate through the first 100 issues, sorted by ID desc, assigned to the user using `issue_assignees` table.
      # For each issue iterated, use IssuesFinder to check if the issue should be counted.
      initializer = IssueAssignee
        .select(:issue_id).joins(", LATERAL (#{finder_constraint.to_sql}) as issues")
        .where(user_id: @current_user.id)
        .order(issue_id: :desc)
        .limit(1)
      recursive_finder = initializer.where("issue_assignees.issue_id < assigned_issues.issue_id")

      cte = <<~SQL
        WITH RECURSIVE assigned_issues AS (
          (
            #{initializer.to_sql}
          )
          UNION ALL
          (
            SELECT next_assigned_issue.issue_id
            FROM assigned_issues,
              LATERAL (
                #{recursive_finder.to_sql}
              ) next_assigned_issue
          )
        ) SELECT COUNT(*) FROM (SELECT * FROM assigned_issues LIMIT #{@max_limit}) issues
      SQL

      ApplicationRecord.connection.execute(cte).first["count"]
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def finder_constraint
      IssuesFinder.new(@current_user, assignee_id: @current_user.id, state: 'opened', non_archived: true)
                  .execute
                  .where("issues.id=issue_assignees.issue_id").limit(1)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
