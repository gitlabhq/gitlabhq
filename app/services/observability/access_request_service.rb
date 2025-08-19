# frozen_string_literal: true

module Observability
  class AccessRequestService < ::BaseService
    include ::Services::ReturnServiceResponses

    DEPLOYER_PROJECT_ID = 71877027

    def initialize(group, current_user)
      @group = group
      @current_user = current_user
    end

    def execute
      return error(s_('Observability|Group is required'), :bad_request) unless @group
      return error(s_('Observability|User is required'), :bad_request) unless @current_user

      unless authorized?
        return error(s_('Observability|You are not authorized to request observability access'),
          :forbidden)
      end

      project = project_for_observability_access_requests
      return error(s_('Observability|Project not found'), :not_found) unless project

      existing_issue = existing_issue?(project)
      return success(issue: existing_issue) if existing_issue

      issue_params = build_issue_params

      result = Issues::CreateService.new(
        container: project,
        current_user: Users::Internal.admin_bot,
        params: issue_params
      ).execute

      if result.success?
        success(issue: result[:issue])
      else
        error_message = result.errors.is_a?(Array) ? result.errors.join(', ') : result.errors.to_s
        error(error_message, :unprocessable_entity)
      end
    end

    private

    attr_reader :group, :current_user, :params

    def authorized?
      ::Feature.enabled?(:observability_sass_features, group) &&
        Ability.allowed?(current_user, :create_observability_access_request, group)
    end

    def build_issue_params
      {
        title: issue_title,
        description: issue_description,
        confidential: true
      }
    end

    def issue_title
      "Request Observability Access for #{group.name}"
    end

    def existing_issue?(project)
      ::IssuesFinder.new(
        Users::Internal.admin_bot,
        {
          project_id: project.id,
          search: issue_title,
          in: 'title',
          state: 'opened'
        }
      ).execute.first
    end

    def issue_description
      member_count = group.members.size

      <<~DESCRIPTION
        ## Observability Access Request

        - **Requesting User:** #{current_user.name} (@#{current_user.username})
        - **Group:** #{group.name} (#{group.full_path})
        - **Request Date:** #{Time.current.strftime('%Y-%m-%d %H:%M:%S UTC')}

        ### Group Information

        - **Group ID:** #{group.id}
        - **Group Path:** #{group.full_path}
        - **Group Visibility:** #{group.visibility_level}
        - **Member Count:** #{member_count}

        ---

        **Note:** This issue has been automatically created as a confidential issue to protect sensitive information. Please review and approve/deny this request according to your organization's access control policies.

      DESCRIPTION
    end

    def project_for_observability_access_requests
      if Rails.env.production?
        Project.find_by_id(DEPLOYER_PROJECT_ID)
      else
        group.projects.first
      end
    end
  end
end
