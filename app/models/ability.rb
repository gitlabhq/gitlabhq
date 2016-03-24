class Ability
  class << self
    def allowed(user, subject)
      return anonymous_abilities(user, subject) if user.nil?
      return [] unless user.is_a?(User)
      return [] if user.blocked?

      abilities =
        case subject
        when CommitStatus then commit_status_abilities(user, subject)
        when Project then project_abilities(user, subject)
        when Issue then issue_abilities(user, subject)
        when ExternalIssue then external_issue_abilities(user, subject)
        when Note then note_abilities(user, subject)
        when ProjectSnippet then project_snippet_abilities(user, subject)
        when PersonalSnippet then personal_snippet_abilities(user, subject)
        when MergeRequest then merge_request_abilities(user, subject)
        when Group then group_abilities(user, subject)
        when Namespace then namespace_abilities(user, subject)
        when GroupMember then group_member_abilities(user, subject)
        when ProjectMember then project_member_abilities(user, subject)
        else []
        end.concat(global_abilities(user))

      abilities -= license_blocked_abilities if License.block_changes?

      abilities
    end

    def license_blocked_abilities
      [
        :create_issue,
        :create_merge_request,
        :push_code,
        :push_code_to_protected_branches
      ]
    end

    # List of possible abilities for anonymous user
    def anonymous_abilities(user, subject)
      case true
      when subject.is_a?(PersonalSnippet)
        anonymous_personal_snippet_abilities(subject)
      when subject.is_a?(CommitStatus)
        anonymous_commit_status_abilities(subject)
      when subject.is_a?(Project) || subject.respond_to?(:project)
        anonymous_project_abilities(subject)
      when subject.is_a?(Group) || subject.respond_to?(:group)
        anonymous_group_abilities(subject)
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
          :read_wiki,
          :read_label,
          :read_milestone,
          :read_project_snippet,
          :read_project_member,
          :read_merge_request,
          :read_note,
          :read_commit_status,
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
      group = if subject.is_a?(Group)
                subject
              else
                subject.group
              end

      if group && group.public?
        [:read_group]
      else
        []
      end
    end

    def anonymous_personal_snippet_abilities(snippet)
      if snippet.public?
        [:read_personal_snippet]
      else
        []
      end
    end

    def global_abilities(user)
      rules = []
      rules << :create_group if user.can_create_group
      rules
    end

    def project_abilities(user, project)
      rules = []
      key = "/user/#{user.id}/project/#{project.id}"

      RequestStore.store[key] ||= begin
        # Push abilities on the users team role
        rules.push(*project_team_rules(project.team, user))

        if project.owner == user ||
          (project.group && project.group.has_owner?(user)) ||
          user.admin?

          rules.push(*project_owner_rules)
        end

        if project.public? || (project.internal? && !user.external?)
          rules.push(*public_project_rules)

          # Allow to read builds for internal projects
          rules << :read_build if project.public_builds?
        end

        if project.archived?
          rules -= project_archived_rules
        end

        rules - project_disabled_features_rules(project)
      end
    end

    def project_team_rules(team, user)
      # Rules based on role in project
      if team.master?(user)
        project_master_rules
      elsif team.developer?(user)
        project_dev_rules
      elsif team.reporter?(user)
        project_report_rules
      elsif team.guest?(user)
        project_guest_rules
      end
    end

    def public_project_rules
      @public_project_rules ||= project_guest_rules + [
        :download_code,
        :fork_project,
        :read_commit_status,
      ]
    end

    def project_guest_rules
      @project_guest_rules ||= [
        :read_project,
        :read_wiki,
        :read_issue,
        :read_label,
        :read_milestone,
        :read_project_snippet,
        :read_project_member,
        :read_merge_request,
        :read_note,
        :create_project,
        :create_issue,
        :create_note,
        :upload_file
      ]
    end

    def project_report_rules
      @project_report_rules ||= project_guest_rules + [
        :download_code,
        :fork_project,
        :create_project_snippet,
        :update_issue,
        :admin_issue,
        :admin_label,
        :read_commit_status,
        :read_build,
      ]
    end

    def project_dev_rules
      @project_dev_rules ||= project_report_rules + [
        :admin_merge_request,
        :update_merge_request,
        :create_commit_status,
        :update_commit_status,
        :create_build,
        :update_build,
        :create_merge_request,
        :create_wiki,
        :push_code
      ]
    end

    def project_archived_rules
      @project_archived_rules ||= [
        :create_merge_request,
        :push_code,
        :push_code_to_protected_branches,
        :update_merge_request,
        :admin_merge_request
      ]
    end

    def project_master_rules
      @project_master_rules ||= project_dev_rules + [
        :read_pages,
        :push_code_to_protected_branches,
        :update_project_snippet,
        :update_pages,
        :admin_milestone,
        :admin_project_snippet,
        :admin_project_member,
        :admin_merge_request,
        :admin_note,
        :admin_wiki,
        :admin_project,
        :admin_commit_status,
        :admin_build,
        :admin_pages,
      ]
    end

    def project_owner_rules
      @project_owner_rules ||= project_master_rules + [
        :change_namespace,
        :change_visibility_level,
        :rename_project,
        :remove_project,
        :remove_pages,
        :archive_project,
        :remove_fork_project,
        :destroy_merge_request,
        :destroy_issue
      ]
    end

    def project_disabled_features_rules(project)
      rules = []

      unless project.issues_enabled
        rules += named_abilities('issue')
      end

      unless project.merge_requests_enabled
        rules += named_abilities('merge_request')
      end

      unless project.issues_enabled or project.merge_requests_enabled
        rules += named_abilities('label')
        rules += named_abilities('milestone')
      end

      unless project.snippets_enabled
        rules += named_abilities('project_snippet')
      end

      unless project.wiki_enabled
        rules += named_abilities('wiki')
      end

      unless project.builds_enabled
        rules += named_abilities('build')
      end

      rules
    end

    def group_abilities(user, group)
      rules = []

      rules << :read_group if can_read_group?(user, group)

      # Only group masters and group owners can create new projects
      if group.has_master?(user) || group.has_owner?(user) || user.admin?
        rules += [
          :create_projects,
          :admin_milestones
        ]
      end

      # Only group owner and administrators can admin group
      if group.has_owner?(user) || user.admin?
        rules += [
          :admin_group,
          :admin_namespace,
          :admin_group_member,
          :change_visibility_level
        ]

        if group.ldap_synced?
          rules.delete(:admin_group_member)
        end
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

    [:note, :project_snippet].each do |name|
      define_method "#{name}_abilities" do |user, subject|
        rules = []

        if subject.author == user
          rules += [
            :"read_#{name}",
            :"update_#{name}",
            :"admin_#{name}"
          ]
        end

        if subject.respond_to?(:project) && subject.project
          rules += project_abilities(user, subject.project)
        end

        rules
      end
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

    def abilities
      @abilities ||= begin
                       abilities = Six.new
                       abilities << self
                       abilities
                     end
    end

    def external_issue_abilities(user, subject)
      project_abilities(user, subject.project)
    end

    private

    def named_abilities(name)
      [
        :"read_#{name}",
        :"create_#{name}",
        :"update_#{name}",
        :"admin_#{name}"
      ]
    end

    def filter_confidential_issues_abilities(user, issue, rules)
      return rules if user.admin? || !issue.confidential?

      unless issue.author == user || issue.assignee == user || issue.project.team.member?(user.id)
        rules.delete(:admin_issue)
        rules.delete(:read_issue)
        rules.delete(:update_issue)
      end

      rules
    end
  end
end
