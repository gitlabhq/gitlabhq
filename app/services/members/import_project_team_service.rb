# frozen_string_literal: true

module Members
  class ImportProjectTeamService < BaseService
    attr_reader :params, :current_user

    def target_project_id
      @target_project_id ||= params[:id].presence
    end

    def source_project_id
      @source_project_id ||= params[:project_id].presence
    end

    def target_project
      @target_project ||= Project.find_by_id(target_project_id)
    end

    def source_project
      @source_project ||= Project.find_by_id(source_project_id)
    end

    def execute
      import_project_team
    end

    private

    def import_project_team
      return false unless target_project.present? && source_project.present? && current_user.present?
      return false unless can?(current_user, :read_project_member, source_project)
      return false unless can?(current_user, :import_project_members_from_another_project, target_project)

      target_project.team.import(source_project, current_user)
    end
  end
end
