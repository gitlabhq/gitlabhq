# UserTeamManager class
#
# Used for manage User teams with project repositories
module Gitlab
  class UserTeamManager
    class << self
      def assign(team, project, access)
        project = Project.find(project) unless project.is_a? Project
        searched_project = team.user_team_project_relationships.find_by_project_id(project.id)

        unless searched_project.present?
          team.user_team_project_relationships.create(project_id: project.id, greatest_access: access)
          update_team_users_access_in_project(team, project)
        end
      end

      def resign(team, project)
        project = Project.find(project) unless project.is_a? Project

        team.user_team_project_relationships.with_project(project).destroy_all

        update_team_users_access_in_project(team, project)
      end

      def update_team_user_membership(team, member, options)
        updates = {}

        if options[:default_projects_access] && options[:default_projects_access] != team.default_projects_access(member)
          updates[:permission] = options[:default_projects_access]
        end

        if options[:group_admin].to_s != team.admin?(member).to_s
          updates[:group_admin] = options[:group_admin].present?
        end

        unless updates.blank?
          user_team_relationship = team.user_team_user_relationships.find_by_user_id(member)
          if user_team_relationship.update_attributes(updates)
            if updates[:permission]
              rebuild_project_permissions_to_member(team, member)
            end
            true
          else
            false
          end
        else
          true
        end
      end

      def update_project_greates_access(team, project, permission)
        project_relation = team.user_team_project_relationships.find_by_project_id(project)
        if permission != team.max_project_access(project)
          if project_relation.update_attributes(greatest_access: permission)
            update_team_users_access_in_project(team, project)
            true
          else
            false
          end
        else
          true
        end
      end

      def rebuild_project_permissions_to_member(team, member)
        team.projects.each do |project|
          update_team_user_access_in_project(team, member, project)
        end
      end

      def update_team_users_access_in_project(team, project)
        members = team.members
        members.each do |member|
          update_team_user_access_in_project(team, member, project)
        end
      end

      def update_team_user_access_in_project(team, user, project)
        granted_access = max_teams_member_permission_in_project(user, project)

        project_team_user = UsersProject.find_by_user_id_and_project_id(user.id, project.id)
        project_team_user.destroy if project_team_user.present?

        # project_team_user.project_access != granted_access
        project.team << [user, granted_access] if granted_access > 0
      end

      def max_teams_member_permission_in_project(user, project, teams = nil)
        result_access = 0

        user_teams = project.user_teams.with_member(user)

        teams ||= user_teams

        if teams.any?
          teams.each do |team|
            granted_access = max_team_member_permission_in_project(team, user, project)
            result_access = [granted_access, result_access].max
          end
        end
        result_access
      end

      def max_team_member_permission_in_project(team, user, project)
        member_access = team.default_projects_access(user)
        team_access = team.user_team_project_relationships.find_by_project_id(project.id).greatest_access

        [team_access, member_access].min
      end

      def add_member_into_team(team, user, access, admin)
        user = User.find(user) unless user.is_a? User

        team.user_team_user_relationships.create(user_id: user.id, permission: access, group_admin: admin)
        team.projects.each do |project|
          update_team_user_access_in_project(team, user, project)
        end
      end

      def remove_member_from_team(team, user)
        user = User.find(user) unless user.is_a? User

        team.user_team_user_relationships.with_user(user).destroy_all
        other_teams = []
        team.projects.each do |project|
          other_teams << project.user_teams.with_member(user)
        end
        other_teams.uniq
        unless other_teams.any?
          UsersProject.in_projects(team.projects).with_user(user).destroy_all
        end
      end
    end
  end
end
