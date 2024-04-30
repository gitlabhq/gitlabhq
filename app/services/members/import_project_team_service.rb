# frozen_string_literal: true

module Members
  class ImportProjectTeamService < BaseService
    ImportProjectTeamForbiddenError = Class.new(StandardError)
    SeatLimitExceededError = Class.new(StandardError)

    def initialize(*args)
      super

      @errors = {}
    end

    def execute
      check_target_and_source_projects_exist!
      check_user_permissions!
      check_seats!

      import_project_team
      process_import_result

      result
    rescue ArgumentError, ImportProjectTeamForbiddenError, SeatLimitExceededError => e
      ServiceResponse.error(message: e.message, reason: e.class.name.demodulize.underscore.to_sym)
    end

    private

    attr_reader :members, :params, :current_user, :errors, :result

    def import_project_team
      @members = target_project.team.import(source_project, current_user)

      if members.is_a?(Array)
        members.each { |member| check_member_validity(member) }
      else
        @result = ServiceResponse.error(message: 'Import failed', reason: :import_failed_error)
      end
    end

    def check_target_and_source_projects_exist!
      if target_project.blank?
        raise ArgumentError, 'Target project does not exist'
      elsif source_project.blank?
        raise ArgumentError, 'Source project does not exist'
      end
    end

    def check_seats!
      # Overridden in EE
    end

    def check_user_permissions!
      return if can?(current_user, :read_project_member, source_project) &&
        can?(current_user, :import_project_members_from_another_project, target_project)

      raise ImportProjectTeamForbiddenError, 'Forbidden'
    end

    def check_member_validity(member)
      return if member.valid?

      errors[member.user.username] = member.errors.full_messages.to_sentence
    end

    def process_import_result
      @result ||= if errors.any?
                    ServiceResponse.error(message: errors, payload: { total_members_count: members.size })
                  else
                    ServiceResponse.success(message: 'Successfully imported')
                  end
    end

    def target_project_id
      params[:id]
    end

    def source_project_id
      params[:project_id]
    end

    def target_project
      @target_project ||= Project.find_by_id(target_project_id)
    end

    def source_project
      @source_project ||= Project.find_by_id(source_project_id)
    end
  end
end

Members::ImportProjectTeamService.prepend_mod_with('Members::ImportProjectTeamService')
