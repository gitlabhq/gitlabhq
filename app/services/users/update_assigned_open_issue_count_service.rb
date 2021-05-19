# frozen_string_literal: true

module Users
  # Service class for calculating and caching the number of assigned open issues for a user.
  class UpdateAssignedOpenIssueCountService
    attr_accessor :target_user

    def initialize(target_user:)
      @target_user = target_user

      raise ArgumentError, "Please provide a target user" unless target_user.is_a?(User)
    end

    def execute
      value = calculate_count
      Rails.cache.write(cache_key, value, expires_in: User::COUNT_CACHE_VALIDITY_PERIOD)

      ServiceResponse.success(payload: { count: value })
    rescue StandardError => e
      ServiceResponse.error(message: e.message)
    end

    private

    def cache_key
      ['users', target_user.id, 'assigned_open_issues_count']
    end

    def calculate_count
      IssuesFinder.new(target_user, assignee_id: target_user.id, state: 'opened', non_archived: true).execute.count
    end
  end
end
