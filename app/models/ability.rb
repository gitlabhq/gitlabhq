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
    def issues_readable_by_user(issues, user = nil)
      DeclarativePolicy.user_scope do
        issues.select { |issue| issue.visible_to_user?(user) }
      end
    end

    def can_edit_note?(user, note)
      allowed?(user, :edit_note, note)
    end

    def allowed?(user, action, subject = :global, opts = {})
      return user.abilities.include?(action) if user.is_a?(Ci::JobUser)

      opts, subject = subject, :global if subject.is_a?(Hash)
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
  end
end
