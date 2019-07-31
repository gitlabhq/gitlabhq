# frozen_string_literal: true

module SelfMonitoring
  module Project
    class CreateService < ::BaseService
      include Stepable

      DEFAULT_VISIBILITY_LEVEL = Gitlab::VisibilityLevel::INTERNAL
      DEFAULT_NAME = 'GitLab Instance Administration'
      DEFAULT_DESCRIPTION = <<~HEREDOC
        This project is automatically generated and will be used to help monitor this GitLab instance.
      HEREDOC

      steps :validate_admins,
        :create_project,
        :add_project_members,
        :add_to_whitelist,
        :add_prometheus_manual_configuration

      def initialize
        super(nil)
      end

      def execute
        execute_steps
      end

      private

      def validate_admins
        unless instance_admins.any?
          log_error('No active admin user found')
          return error('No active admin user found')
        end

        success
      end

      def create_project
        admin_user = project_owner
        @project = ::Projects::CreateService.new(admin_user, create_project_params).execute

        if project.persisted?
          success(project: project)
        else
          log_error("Could not create self-monitoring project. Errors: #{project.errors.full_messages}")
          error('Could not create project')
        end
      end

      def add_project_members
        members = project.add_users(project_maintainers, Gitlab::Access::MAINTAINER)
        errors = members.flat_map { |member| member.errors.full_messages }

        if errors.any?
          log_error("Could not add admins as members to self-monitoring project. Errors: #{errors}")
          error('Could not add admins as members')
        else
          success
        end
      end

      def add_to_whitelist
        return success unless prometheus_enabled?
        return success unless prometheus_listen_address.present?

        uri = parse_url(internal_prometheus_listen_address_uri)
        return error(_('Prometheus listen_address is not a valid URI')) unless uri

        result = ApplicationSettings::UpdateService.new(
          Gitlab::CurrentSettings.current_application_settings,
          project_owner,
          outbound_local_requests_whitelist: [uri.normalized_host]
        ).execute

        if result
          success
        else
          error(_('Could not add prometheus URL to whitelist'))
        end
      end

      def add_prometheus_manual_configuration
        return success unless prometheus_enabled?
        return success unless prometheus_listen_address.present?

        service = project.find_or_initialize_service('prometheus')

        unless service.update(prometheus_service_attributes)
          log_error("Could not save prometheus manual configuration for self-monitoring project. Errors: #{service.errors.full_messages}")
          return error('Could not save prometheus manual configuration')
        end

        success
      end

      def parse_url(uri_string)
        Addressable::URI.parse(uri_string)
      rescue Addressable::URI::InvalidURIError, TypeError
      end

      def prometheus_enabled?
        Gitlab.config.prometheus.enable
      rescue Settingslogic::MissingSetting
        false
      end

      def prometheus_listen_address
        Gitlab.config.prometheus.listen_address
      rescue Settingslogic::MissingSetting
      end

      def instance_admins
        @instance_admins ||= User.admins.active
      end

      def project_owner
        instance_admins.first
      end

      def project_maintainers
        # Exclude the first so that the project_owner is not added again as a member.
        instance_admins - [project_owner]
      end

      def create_project_params
        {
          initialize_with_readme: true,
          visibility_level: DEFAULT_VISIBILITY_LEVEL,
          name: DEFAULT_NAME,
          description: DEFAULT_DESCRIPTION
        }
      end

      def internal_prometheus_listen_address_uri
        if prometheus_listen_address.starts_with?('http')
          prometheus_listen_address
        else
          'http://' + prometheus_listen_address
        end
      end

      def prometheus_service_attributes
        {
          api_url: internal_prometheus_listen_address_uri,
          manual_configuration: true,
          active: true
        }
      end
    end
  end
end
