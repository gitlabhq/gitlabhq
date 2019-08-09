# frozen_string_literal: true

module SelfMonitoring
  module Project
    class CreateService < ::BaseService
      include Stepable
      include Gitlab::Utils::StrongMemoize

      VISIBILITY_LEVEL = Gitlab::VisibilityLevel::INTERNAL
      PROJECT_NAME = 'GitLab Instance Administration'
      PROJECT_DESCRIPTION = <<~HEREDOC
        This project is automatically generated and will be used to help monitor this GitLab instance.
      HEREDOC

      GROUP_NAME = 'GitLab Instance Administrators'
      GROUP_PATH = 'gitlab-instance-administrators'

      steps :validate_admins,
        :create_group,
        :create_project,
        :save_project_id,
        :add_group_members,
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

      def create_group
        if project_created?
          log_info(_('Instance administrators group already exists'))
          @group = application_settings.instance_administration_project.owner
          return success(group: @group)
        end

        admin_user = group_owner
        @group = ::Groups::CreateService.new(admin_user, create_group_params).execute

        if @group.persisted?
          success(group: @group)
        else
          error('Could not create group')
        end
      end

      def create_project
        if project_created?
          log_info(_('Instance administration project already exists'))
          @project = application_settings.instance_administration_project
          return success(project: project)
        end

        admin_user = group_owner
        @project = ::Projects::CreateService.new(admin_user, create_project_params).execute

        if project.persisted?
          success(project: project)
        else
          log_error(_("Could not create instance administration project. Errors: %{errors}") % { errors: project.errors.full_messages })
          error(_('Could not create project'))
        end
      end

      def save_project_id
        return success if project_created?

        result = ApplicationSettings::UpdateService.new(
          application_settings,
          group_owner,
          { instance_administration_project_id: @project.id }
        ).execute

        if result
          success
        else
          log_error(_("Could not save instance administration project ID, errors: %{errors}") % { errors: application_settings.errors.full_messages })
          error(_('Could not save project ID'))
        end
      end

      def add_group_members
        members = @group.add_users(group_maintainers, Gitlab::Access::MAINTAINER)
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
          application_settings,
          group_owner,
          add_to_outbound_local_requests_whitelist: [uri.normalized_host]
        ).execute

        if result
          success
        else
          log_error(_("Could not add prometheus URL to whitelist, errors: %{errors}") % { errors: application_settings.errors.full_messages })
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

      def application_settings
        strong_memoize(:application_settings) do
          Gitlab::CurrentSettings.expire_current_application_settings
          Gitlab::CurrentSettings.current_application_settings
        end
      end

      def project_created?
        application_settings.instance_administration_project.present?
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

      def group_owner
        instance_admins.first
      end

      def group_maintainers
        # Exclude the first so that the group_owner is not added again as a member.
        instance_admins - [group_owner]
      end

      def create_group_params
        {
          name: GROUP_NAME,
          path: "#{GROUP_PATH}-#{SecureRandom.hex(4)}",
          visibility_level: VISIBILITY_LEVEL
        }
      end

      def create_project_params
        {
          initialize_with_readme: true,
          visibility_level: VISIBILITY_LEVEL,
          name: PROJECT_NAME,
          description: PROJECT_DESCRIPTION,
          namespace_id: @group.id
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
