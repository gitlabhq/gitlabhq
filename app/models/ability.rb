require_dependency 'declarative_policy'

class Ability
  class << self
    # Given a list of users and a project this method returns the users that can
    # read the given project.
    def users_that_can_read_project(users, project)
      DeclarativePolicy.subject_scope do
        users.select { |u| allowed?(u, :read_project, project) }
      end
    end

    # Given a list of users and a snippet this method returns the users that can
    # read the given snippet.
    def users_that_can_read_personal_snippet(users, snippet)
      DeclarativePolicy.subject_scope do
        users.select { |u| allowed?(u, :read_personal_snippet, snippet) }
      end
    end

    # Returns an Array of Issues that can be read by the given user.
    #
    # issues - The issues to reduce down to those readable by the user.
    # user - The User for which to check the issues
    # filters - A hash of abilities and filters to apply if the user lacks this
    #           ability
    def issues_readable_by_user(issues, user = nil, filters: {})
      issues = apply_filters_if_needed(issues, user, filters)

      DeclarativePolicy.user_scope do
        issues.select { |issue| issue.visible_to_user?(user) }
      end
    end

    # Returns an Array of MergeRequests that can be read by the given user.
    #
    # merge_requests - MRs out of which to collect mr's readable by the user.
    # user - The User for which to check the merge_requests
    # filters - A hash of abilities and filters to apply if the user lacks this
    #           ability
    def merge_requests_readable_by_user(merge_requests, user = nil, filters: {})
      merge_requests = apply_filters_if_needed(merge_requests, user, filters)

      DeclarativePolicy.user_scope do
        merge_requests.select { |mr| allowed?(user, :read_merge_request, mr) }
      end
    end

    def allowed?(user, action, subject = :global, opts = {})
      if subject.is_a?(Hash)
        opts, subject = subject, :global
      end

      policy = policy_for(user, subject)

      case opts[:scope]
      when :user
        DeclarativePolicy.user_scope { policy.can?(action) }
      when :subject
        DeclarativePolicy.subject_scope { policy.can?(action) }
      else
        policy.can?(action)
      end
    end

    def policy_for(user, subject = :global)
      cache = RequestStore.active? ? RequestStore : {}
      DeclarativePolicy.policy_for(user, subject, cache: cache)
    end

    private

    def apply_filters_if_needed(elements, user, filters)
      filters.each do |ability, filter|
        elements = filter.call(elements) unless allowed?(user, ability)
      end

      elements
    end
  end
end
