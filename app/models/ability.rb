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

    def allowed?(user, action, subject)
      allowed(user, subject).include?(action)
    end

    def allowed(user, subject)
      return uncached_allowed(user, subject) unless RequestStore.active?

      user_key = user ? user.id : 'anonymous'
      subject_key = subject ? "#{subject.class.name}/#{subject.id}" : 'global'
      key = "/ability/#{user_key}/#{subject_key}"
      RequestStore[key] ||= Set.new(uncached_allowed(user, subject)).freeze
    end

    private

    def uncached_allowed(user, subject)
      policy_class = BasePolicy.class_for(subject) rescue nil
      return policy_class.abilities(user, subject) if policy_class

      return anonymous_abilities(subject) if user.nil?
      return [] unless user.is_a?(User)
      return [] if user.blocked?

      abilities_by_subject_class(user: user, subject: subject)
    end

    def abilities_by_subject_class(user:, subject:)
      case subject
      when ExternalIssue, Deployment, Environment then project_abilities(user, subject.project)
      else []
      end + global_abilities(user)
    end

    # List of possible abilities for anonymous user
    def anonymous_abilities(subject)
      if subject.respond_to?(:project)
        ProjectPolicy.abilities(nil, subject.project)
      elsif subject.respond_to?(:group)
        GroupPolicy.abilities(nil, subject.group)
      else
        []
      end
    end

    def global_abilities(user)
      rules = []
      rules << :create_group if user.can_create_group
      rules << :read_users_list
      rules
    end

    def project_abilities(user, project)
      # temporary patch, deleteme before merge
      ProjectPolicy.abilities(user, project).to_a
    end

    def project_member_abilities(user, subject)
      rules = []
      target_user = subject.user
      project = subject.project

      unless target_user == project.owner
        can_manage = allowed?(user, :admin_project_member, project)

        if can_manage
          rules << :update_project_member
          rules << :destroy_project_member
        elsif user == target_user
          rules << :destroy_project_member
        end
      end

      rules
    end

    def filter_build_abilities(rules)
      # If we can't read build we should also not have that
      # ability when looking at this in context of commit_status
      %w(read create update admin).each do |rule|
        rules.delete(:"#{rule}_commit_status") unless rules.include?(:"#{rule}_build")
      end
      rules
    end

    def restricted_public_level?
      current_application_settings.restricted_visibility_levels.include?(Gitlab::VisibilityLevel::PUBLIC)
    end

    def filter_confidential_issues_abilities(user, issue, rules)
      return rules if user.admin? || !issue.confidential?

      unless issue.author == user || issue.assignee == user || issue.project.team.member?(user, Gitlab::Access::REPORTER)
        rules.delete(:admin_issue)
        rules.delete(:read_issue)
        rules.delete(:update_issue)
      end

      rules
    end
  end
end
