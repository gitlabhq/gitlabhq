# frozen_string_literal: true

module JiraImport
  class UsersImporter
    def initialize(user, project, start_at)
      @project = project
      @start_at = start_at
      @user = user
    end

    def execute
      Gitlab::JiraImport.validate_project_settings!(project, user: user)

      ServiceResponse.success(payload: mapped_users)
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, URI::InvalidURIError, JIRA::HTTPError, OpenSSL::SSL::SSLError => error
      Gitlab::ErrorTracking.log_exception(error, project_id: project.id)
      ServiceResponse.error(message: "There was an error when communicating to Jira")
    rescue Projects::ImportService::Error => error
      ServiceResponse.error(message: error.message)
    end

    private

    attr_reader :user, :project, :start_at

    def mapped_users
      users_mapper_service.execute
    end

    def users_mapper_service
      @users_mapper_service ||= user_mapper_service_factory
    end

    def user_mapper_service_factory
      if project.jira_integration.data_fields.deployment_server?
        ServerUsersMapperService.new(user, project, start_at)
      elsif project.jira_integration.data_fields.deployment_cloud?
        CloudUsersMapperService.new(user, project, start_at)
      else
        raise ArgumentError
      end
    end
  end
end
