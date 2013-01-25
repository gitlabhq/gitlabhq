class Ability
  class << self
    def allowed(user, subject)
      return [] unless user.kind_of?(User)

      case subject.class.name
      when "Project" then project_abilities(user, subject)
      when "Issue" then issue_abilities(user, subject)
      when "Note" then note_abilities(user, subject)
      when "Snippet" then snippet_abilities(user, subject)
      when "MergeRequest" then merge_request_abilities(user, subject)
      when "Group", "Namespace" then group_abilities(user, subject)
      when "UserTeam" then user_team_abilities(user, subject)
      else []
      end.concat(global_abilities(user))
    end

    def global_abilities(user)
      rules = []
      rules << :create_group if user.can_create_group
      rules << :create_team if user.can_create_team
      rules
    end

    def project_abilities(user, project)
      rules = []

      team = project.team

      # Rules based on role in project
      if team.masters.include?(user)
        rules << project_master_rules

      elsif team.developers.include?(user)
        rules << project_dev_rules

      elsif team.reporters.include?(user)
        rules << project_report_rules

      elsif team.guests.include?(user)
        rules << project_guest_rules
      end

      if project.owner == user
        rules << project_admin_rules
      end

      rules.flatten
    end

    def project_guest_rules
      [
        :read_project,
        :read_wiki,
        :read_issue,
        :read_milestone,
        :read_snippet,
        :read_team_member,
        :read_merge_request,
        :read_note,
        :write_project,
        :write_issue,
        :write_note
      ]
    end

    def project_report_rules
      project_guest_rules + [
        :download_code,
        :write_snippet
      ]
    end

    def project_dev_rules
      project_report_rules + [
        :write_merge_request,
        :write_wiki,
        :push_code
      ]
    end

    def project_master_rules
      project_dev_rules + [
        :push_code_to_protected_branches,
        :modify_issue,
        :modify_snippet,
        :modify_merge_request,
        :admin_issue,
        :admin_milestone,
        :admin_snippet,
        :admin_team_member,
        :admin_merge_request,
        :admin_note,
        :accept_mr,
        :admin_wiki,
        :admin_project
      ]
    end

    def project_admin_rules
      project_master_rules + [
        :change_namespace,
        :change_public_mode,
        :rename_project,
        :remove_project
      ]
    end

    def group_abilities user, group
      rules = []

      # Only group owner and administrators can manage group
      if group.owner == user || user.admin?
        rules << [
          :manage_group,
          :manage_namespace
        ]
      end

      rules.flatten
    end

    def user_team_abilities user, team
      rules = []

      # Only group owner and administrators can manage group
      if team.owner == user || team.admin?(user) || user.admin?
        rules << [ :manage_user_team ]
      end

      if team.owner == user || user.admin?
        rules << [ :admin_user_team ]
      end

      rules.flatten
    end


    [:issue, :note, :snippet, :merge_request].each do |name|
      define_method "#{name}_abilities" do |user, subject|
        if subject.author == user
          [
            :"read_#{name}",
            :"write_#{name}",
            :"modify_#{name}",
            :"admin_#{name}"
          ]
        elsif subject.respond_to?(:assignee) && subject.assignee == user
          [
            :"read_#{name}",
            :"write_#{name}",
            :"modify_#{name}",
          ]
        else
          subject.respond_to?(:project) ? project_abilities(user, subject.project) : []
        end
      end
    end
  end
end
