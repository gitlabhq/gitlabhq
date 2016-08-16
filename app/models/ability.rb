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
      return anonymous_abilities(subject) if user.nil?
      return [] unless user.is_a?(User)
      return [] if user.blocked?

      abilities_by_subject_class(user: user, subject: subject)
    end

    def abilities_by_subject_class(user:, subject:)
      case subject
      when Project then ProjectPolicy.abilities(user, subject)
      when Issue then IssuePolicy.abilities(user, subject)
      when MergeRequest then MergeRequestPolicy.abilities(user, subject)

      when Ci::Build then Ci::BuildPolicy.abilities(user, subject)
      when CommitStatus then CommitStatus.abilities(user, subject)
      when Note then note_abilities(user, subject)
      when ProjectSnippet then project_snippet_abilities(user, subject)
      when PersonalSnippet then personal_snippet_abilities(user, subject)
      when Group then group_abilities(user, subject)
      when Namespace then namespace_abilities(user, subject)
      when GroupMember then group_member_abilities(user, subject)
      when ProjectMember then project_member_abilities(user, subject)
      when User then user_abilities
      when ExternalIssue, Deployment, Environment then project_abilities(user, subject.project)
      when Ci::Runner then runner_abilities(user, subject)
      else []
      end + global_abilities(user)
    end

    # List of possible abilities for anonymous user
    def anonymous_abilities(subject)
      if subject.is_a?(PersonalSnippet)
        anonymous_personal_snippet_abilities(subject)
      elsif subject.is_a?(ProjectSnippet)
        anonymous_project_snippet_abilities(subject)
      elsif subject.is_a?(CommitStatus)
        anonymous_commit_status_abilities(subject)
      elsif subject.is_a?(Project)
        ProjectPolicy.abilities(nil, subject)
      elsif subject.is_a?(Issue)
        IssuePolicy.abilities(nil, subject)
      elsif subject.is_a?(MergeRequest)
        MergeRequestPolicy.abilities(nil, subject)
      elsif subject.respond_to?(:project)
        ProjectPolicy.abilities(nil, subject.project)
      elsif subject.is_a?(Group) || subject.respond_to?(:group)
        anonymous_group_abilities(subject)
      elsif subject.is_a?(User)
        anonymous_user_abilities
      else
        []
      end
    end

    def anonymous_project_abilities(subject)
      project = if subject.is_a?(Project)
                  subject
                else
                  subject.project
                end

      if project && project.public?
        rules = [
          :read_project,
          :read_board,
          :read_list,
          :read_wiki,
          :read_label,
          :read_milestone,
          :read_project_snippet,
          :read_project_member,
          :read_merge_request,
          :read_note,
          :read_pipeline,
          :read_commit_status,
          :read_container_image,
          :download_code
        ]

        # Allow to read builds by anonymous user if guests are allowed
        rules << :read_build if project.public_builds?

        # Allow to read issues by anonymous user if issue is not confidential
        rules << :read_issue unless subject.is_a?(Issue) && subject.confidential?

        rules - project_disabled_features_rules(project)
      else
        []
      end
    end

    def anonymous_commit_status_abilities(subject)
      rules = anonymous_project_abilities(subject.project)
      # If subject is Ci::Build which inherits from CommitStatus filter the abilities
      rules = filter_build_abilities(rules) if subject.is_a?(Ci::Build)
      rules
    end

    def anonymous_group_abilities(subject)
      rules = []

      group = if subject.is_a?(Group)
                subject
              else
                subject.group
              end

      rules << :read_group if group.public?

      rules
    end

    def anonymous_personal_snippet_abilities(snippet)
      if snippet.public?
        [:read_personal_snippet]
      else
        []
      end
    end

    def anonymous_project_snippet_abilities(snippet)
      if snippet.public?
        [:read_project_snippet]
      else
        []
      end
    end

    def anonymous_user_abilities
      [:read_user] unless restricted_public_level?
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

    def group_abilities(user, group)
      rules = []
      rules << :read_group if can_read_group?(user, group)

      owner = user.admin? || group.has_owner?(user)
      master = owner || group.has_master?(user)

      # Only group masters and group owners can create new projects
      if master
        rules += [
          :create_projects,
          :admin_milestones
        ]
      end

      # Only group owner and administrators can admin group
      if owner
        rules += [
          :admin_group,
          :admin_namespace,
          :admin_group_member,
          :change_visibility_level
        ]
      end

      if group.public? || (group.internal? && !user.external?)
        rules << :request_access if group.request_access_enabled && group.users.exclude?(user)
      end

      rules.flatten
    end

    def can_read_group?(user, group)
      return true if user.admin?
      return true if group.public?
      return true if group.internal? && !user.external?
      return true if group.users.include?(user)

      GroupProjectsFinder.new(group).execute(user).any?
    end

    def namespace_abilities(user, namespace)
      rules = []

      # Only namespace owner and administrators can admin it
      if namespace.owner == user || user.admin?
        rules += [
          :create_projects,
          :admin_namespace
        ]
      end

      rules.flatten
    end

    [:issue, :merge_request].each do |name|
      define_method "#{name}_abilities" do |user, subject|
        rules = []

        if subject.author == user || (subject.respond_to?(:assignee) && subject.assignee == user)
          rules += [
            :"read_#{name}",
            :"update_#{name}",
          ]
        end

        rules += project_abilities(user, subject.project)
        rules = filter_confidential_issues_abilities(user, subject, rules) if subject.is_a?(Issue)
        rules
      end
    end

    def note_abilities(user, note)
      rules = []

      if note.author == user
        rules += [
          :read_note,
          :update_note,
          :admin_note,
          :resolve_note
        ]
      end

      if note.respond_to?(:project) && note.project
        rules += project_abilities(user, note.project)
      end

      if note.for_merge_request? && note.noteable.author == user
        rules << :resolve_note
      end

      rules
    end

    def personal_snippet_abilities(user, snippet)
      rules = []

      if snippet.author == user
        rules += [
          :read_personal_snippet,
          :update_personal_snippet,
          :admin_personal_snippet
        ]
      end

      if snippet.public? || (snippet.internal? && !user.external?)
        rules << :read_personal_snippet
      end

      rules
    end

    def project_snippet_abilities(user, snippet)
      rules = []

      if snippet.author == user || user.admin?
        rules += [
          :read_project_snippet,
          :update_project_snippet,
          :admin_project_snippet
        ]
      end

      if snippet.public? || (snippet.internal? && !user.external?) || (snippet.private? && snippet.project.team.member?(user))
        rules << :read_project_snippet
      end

      rules
    end

    def group_member_abilities(user, subject)
      rules = []
      target_user = subject.user
      group = subject.group

      unless group.last_owner?(target_user)
        can_manage = group_abilities(user, group).include?(:admin_group_member)

        if can_manage
          rules << :update_group_member
          rules << :destroy_group_member
        elsif user == target_user
          rules << :destroy_group_member
        end
      end

      rules
    end

    def project_member_abilities(user, subject)
      rules = []
      target_user = subject.user
      project = subject.project

      unless target_user == project.owner
        can_manage = project_abilities(user, project).include?(:admin_project_member)

        if can_manage
          rules << :update_project_member
          rules << :destroy_project_member
        elsif user == target_user
          rules << :destroy_project_member
        end
      end

      rules
    end

    def commit_status_abilities(user, subject)
      rules = project_abilities(user, subject.project)
      # If subject is Ci::Build which inherits from CommitStatus filter the abilities
      rules = filter_build_abilities(rules) if subject.is_a?(Ci::Build)
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

    def runner_abilities(user, runner)
      if user.is_admin?
        [:assign_runner]
      elsif runner.is_shared? || runner.locked?
        []
      elsif user.ci_authorized_runners.include?(runner)
        [:assign_runner]
      else
        []
      end
    end

    def user_abilities
      [:read_user]
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
