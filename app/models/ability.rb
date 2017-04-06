class Ability
  class << self
    # Given a list of users and a project this method returns the users that can
    # read the given project.
    def users_that_can_read_project(users, project)
      if project.public?
        users
      else
        users.select do |user|
          if user.admin?
            true
          elsif project.internal? && !user.external?
            true
          elsif project.owner == user
            true
          elsif project.team.members.include?(user)
            true
          else
            false
          end
        end
      end
    end

    # Given a list of users and a snippet this method returns the users that can
    # read the given snippet.
    def users_that_can_read_personal_snippet(users, snippet)
      case snippet.visibility_level
      when Snippet::INTERNAL, Snippet::PUBLIC
        users
      when Snippet::PRIVATE
        users.include?(snippet.author) ? [snippet.author] : []
      end
    end

    # Returns an Array of Issues that can be read by the given user.
    #
    # issues - The issues to reduce down to those readable by the user.
    # user - The User for which to check the issues
    def issues_readable_by_user(issues, user = nil)
      return issues if user && user.admin?

      issues.select { |issue| issue.visible_to_user?(user) }
    end

    # TODO: make this private and use the actual abilities stuff for this
    def can_edit_note?(user, note)
      return false if !note.editable? || !user.present?
      return true if note.author == user || user.admin?

      if note.project
        max_access_level = note.project.team.max_member_access(user.id)
        max_access_level >= Gitlab::Access::MASTER
      else
        false
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
  end
end
