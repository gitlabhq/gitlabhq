# frozen_string_literal: true

module Observability
  class AccessRequestService < ::BaseService
    include ::Services::ReturnServiceResponses

    DEPLOYER_PROJECT_ID = 71877027

    # namespace - the Group or personal (user) Namespace the setting belongs to.
    # project - required for personal namespaces: the initiating project, used
    #   for the authorization check and as the container for the CI export
    #   variable (user namespaces have no CI variables of their own).
    def initialize(namespace, current_user, project: nil)
      @namespace = namespace
      @current_user = current_user
      @project = project
    end

    def execute
      return error(s_('Observability|Namespace is required'), :bad_request) unless @namespace
      return error(s_('Observability|User is required'), :bad_request) unless @current_user

      unless authorized?
        return error(s_('Observability|You are not authorized to request observability access'),
          :forbidden)
      end

      issue_project = project_for_observability_access_requests
      return error(s_('Observability|Project not found'), :not_found) unless issue_project

      existing_issue = existing_issue?(issue_project)
      return success(issue: existing_issue) if existing_issue

      issue_params = build_issue_params

      result = Issues::CreateService.new(
        container: issue_project,
        current_user: Users::Internal.admin_bot,
        params: issue_params
      ).execute

      if result.success?
        create_temporary_o11y_setting(namespace)
        Observability::CreateGroupO11ySettingWorker.perform_async(current_user.id, namespace.id, project&.id)
        success(issue: result[:issue])
      else
        error_message = result.errors.is_a?(Array) ? result.errors.join(', ') : result.errors.to_s
        error(error_message, :unprocessable_entity)
      end
    end

    private

    attr_reader :namespace, :current_user, :project, :params

    def authorized?
      return false unless feature_enabled?

      if group_namespace?
        Ability.allowed?(current_user, :create_observability_access_request, namespace)
      else
        # Personal namespaces have no policy surface for this permission; it is
        # granted at the project level (owner only) instead.
        project.present? && project.namespace == namespace &&
          Ability.allowed?(current_user, :create_observability_access_request, project)
      end
    end

    def feature_enabled?
      if group_namespace?
        ::Feature.enabled?(:observability_sass_features, namespace)
      else
        ::Feature.enabled?(:observability_saas_features_user_namespace, namespace)
      end
    end

    def group_namespace?
      namespace.is_a?(Group)
    end

    def build_issue_params
      {
        title: issue_title,
        description: issue_description,
        confidential: true
      }
    end

    def issue_title
      "Request Observability Access for #{namespace.name}"
    end

    def existing_issue?(issue_project)
      ::IssuesFinder.new(
        Users::Internal.admin_bot,
        {
          project_id: issue_project.id,
          search: issue_title,
          in: 'title',
          state: 'opened'
        }
      ).execute.first
    end

    def issue_description
      <<~DESCRIPTION
        ## Observability Access Request

        - **Requesting User:** #{current_user.name} (@#{current_user.username}) - #{current_user.email}
        - **Namespace:** #{namespace.name} (#{namespace.full_path})
        - **Request Date:** #{Time.current.strftime('%Y-%m-%d %H:%M:%S UTC')}

        ### Namespace Information

        - **Namespace ID:** #{namespace.id}
        - **Namespace Path:** #{namespace.full_path}
        - **Namespace Type:** #{namespace_type}
        - **Namespace Visibility:** #{namespace.visibility_level}
        - **Member Count:** #{member_count}

        ---

        **Note:** This issue has been automatically created as a confidential issue to protect sensitive information. Please review and approve/deny this request according to your organization's access control policies.

      DESCRIPTION
    end

    def namespace_type
      group_namespace? ? 'Group' : 'Personal namespace'
    end

    def member_count
      # User namespaces have no members association; the owner is the only member.
      group_namespace? ? namespace.members.size : 1
    end

    def project_for_observability_access_requests
      if Rails.env.production?
        Project.find_by_id(DEPLOYER_PROJECT_ID)
      else
        namespace.projects.projects_order_id_asc.first
      end
    end

    def create_temporary_o11y_setting(namespace)
      return if namespace.observability_group_o11y_setting.present?

      setting = namespace.build_observability_group_o11y_setting
      ::Observability::GroupO11ySettingsUpdateService.new.execute(setting, settings_params)
    end

    def settings_params
      {
        o11y_service_name: namespace.id.to_s,
        o11y_service_user_email: "#{namespace.id}@gitlab-o11y.com",
        o11y_service_password: SecureRandom.hex(16),
        o11y_service_post_message_encryption_key: SecureRandom.hex(32)
      }
    end
  end
end
