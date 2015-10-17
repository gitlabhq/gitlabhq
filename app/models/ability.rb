class Ability
  class << self
    def allowed(user, subject)
      return not_auth_abilities(user, subject) if user.nil?
      return [] unless user.kind_of?(User)
      return [] if user.blocked?

      case subject.class.name
      when "Project" then project_abilities(user, subject)
      when "Issue" then issue_abilities(user, subject)
      when "Note" then note_abilities(user, subject)
      when "ProjectSnippet" then project_snippet_abilities(user, subject)
      when "PersonalSnippet" then personal_snippet_abilities(user, subject)
      when "MergeRequest" then merge_request_abilities(user, subject)
      when "Group" then group_abilities(user, subject)
      when "Namespace" then namespace_abilities(user, subject)
      when "GroupMember" then group_member_abilities(user, subject)
      else []
      end.concat(global_abilities(user))
    end

    # List of possible abilities
    # for non-authenticated user
    def not_auth_abilities(user, subject)
      project = if subject.kind_of?(Project)
                  subject
                elsif subject.respond_to?(:project)
                  subject.project
                else
                  nil
                end

      if project && project.public?
        rules = [
          :read_project,
          :read_wiki,
          :read_issue,
          :read_label,
          :read_milestone,
          :read_project_snippet,
          :read_project_member,
          :read_merge_request,
          :read_note,
          :read_build,
          :download_code
        ]

        rules - project_disabled_features_rules(project)
      else
        group = if subject.kind_of?(Group)
                  subject
                elsif subject.respond_to?(:group)
                  subject.group
                else
                  nil
                end

        if group && group.public_profile?
          [:read_group]
        else
          []
        end
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
        team = project.team

        # Rules based on role in project
        if team.master?(user)
          rules.push(*project_master_rules)

        elsif team.developer?(user)
          rules.push(*project_dev_rules)

        elsif team.reporter?(user)
          rules.push(*project_report_rules)

        elsif team.guest?(user)
          rules.push(*project_guest_rules)
        end

        if project.public? || project.internal?
          rules.push(*public_project_rules)
        end

        if project.owner == user || user.admin?
          rules.push(*project_admin_rules)
        end

        if project.group && project.group.has_owner?(user)
          rules.push(*project_admin_rules)
        end

        if project.archived?
          rules -= project_archived_rules
        end

        rules - project_disabled_features_rules(project)
      end
    end

    def public_project_rules
      project_guest_rules + [
        :download_code,
        :fork_project
      ]
    end

    def project_guest_rules
      [
        :read_project,
        :read_wiki,
        :read_issue,
        :read_label,
        :read_milestone,
        :read_project_snippet,
        :read_project_member,
        :read_merge_request,
        :read_note,
        :read_build,
        :create_project,
        :create_issue,
        :create_note
      ]
    end

    def project_report_rules
      project_guest_rules + [
        :create_commit_status,
        :read_commit_statuses,
        :download_code,
        :fork_project,
        :create_project_snippet,
        :update_issue,
        :admin_issue,
        :admin_label
      ]
    end

    def project_dev_rules
      project_report_rules + [
        :admin_merge_request,
        :create_merge_request,
        :create_wiki,
        :manage_builds,
        :push_code
      ]
    end

    def project_archived_rules
      [
        :create_merge_request,
        :push_code,
        :push_code_to_protected_branches,
        :update_merge_request,
        :admin_merge_request
      ]
    end

    def project_master_rules
      project_dev_rules + [
        :push_code_to_protected_branches,
        :update_project_snippet,
        :update_merge_request,
        :admin_milestone,
        :admin_project_snippet,
        :admin_project_member,
        :admin_merge_request,
        :admin_note,
        :admin_wiki,
        :admin_project
      ]
    end

    def project_admin_rules
      project_master_rules + [
        :change_namespace,
        :change_visibility_level,
        :rename_project,
        :remove_project,
        :archive_project
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

      rules
    end

    def group_abilities(user, group)
      rules = []

      if user.admin? || group.users.include?(user) || ProjectsFinder.new.execute(user, group: group).any?
        rules << :read_group
      end

      # Only group masters and group owners can create new projects in group
      if group.has_master?(user) || group.has_owner?(user) || user.admin?
        rules.push(*[
          :create_projects,
        ])
      end

      # Only group owner and administrators can admin group
      if group.has_owner?(user) || user.admin?
        rules.push(*[
          :admin_group,
          :admin_namespace,
          :admin_group_member
        ])
      end

      rules.flatten
    end

    def namespace_abilities(user, namespace)
      rules = []

      # Only namespace owner and administrators can admin it
      if namespace.owner == user || user.admin?
        rules.push(*[
          :create_projects,
          :admin_namespace
        ])
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
        rules
      end
    end

    [:note, :project_snippet, :personal_snippet].each do |name|
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

    def group_member_abilities(user, subject)
      rules = []
      target_user = subject.user
      group = subject.group
      can_manage = group_abilities(user, group).include?(:admin_group_member)

      if can_manage && (user != target_user)
        rules << :update_group_member
        rules << :destroy_group_member
      end

      if !group.last_owner?(user) && (can_manage || (user == target_user))
        rules << :destroy_group_member
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

    private

    def named_abilities(name)
      [
        :"read_#{name}",
        :"create_#{name}",
        :"update_#{name}",
        :"admin_#{name}"
      ]
    end
  end
end
