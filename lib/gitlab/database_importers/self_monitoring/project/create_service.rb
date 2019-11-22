# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    module SelfMonitoring
      module Project
        class CreateService < ::BaseService
          include Stepable

          STEPS_ALLOWED_TO_FAIL = [
            :validate_application_settings, :validate_project_created, :validate_admins
          ].freeze

          VISIBILITY_LEVEL = Gitlab::VisibilityLevel::INTERNAL
          PROJECT_NAME = 'GitLab Instance Administration'

          steps :validate_application_settings,
            :validate_project_created,
            :validate_admins,
            :create_group,
            :create_project,
            :save_project_id,
            :add_group_members,
            :add_prometheus_manual_configuration

          def initialize
            super(nil)
          end

          def execute!
            result = execute_steps
            if result[:status] == :success
              ::Gitlab::Tracking.event("self_monitoring", "project_created")
              result
            elsif STEPS_ALLOWED_TO_FAIL.include?(result[:last_step])
              ::Gitlab::Tracking.event("self_monitoring", "project_created")
              success
            else
              raise StandardError, result[:message]
            end
          end

          private

          def validate_application_settings(_result)
            return success if application_settings

            log_error('No application_settings found')
            error(_('No application_settings found'))
          end

          def validate_project_created(result)
            return success(result) unless project_created?

            log_error('Project already created')
            error(_('Project already created'))
          end

          def validate_admins(result)
            unless instance_admins.any?
              log_error('No active admin user found')
              return error(_('No active admin user found'))
            end

            success(result)
          end

          def create_group(result)
            if project_created?
              log_info(_('Instance administrators group already exists'))
              result[:group] = application_settings.instance_administration_project.owner
              return success(result)
            end

            result[:group] = ::Groups::CreateService.new(group_owner, create_group_params).execute

            if result[:group].persisted?
              success(result)
            else
              error(_('Could not create group'))
            end
          end

          def create_project(result)
            if project_created?
              log_info('Instance administration project already exists')
              result[:project] = application_settings.instance_administration_project
              return success(result)
            end

            result[:project] = ::Projects::CreateService.new(group_owner, create_project_params(result[:group])).execute

            if result[:project].persisted?
              success(result)
            else
              log_error("Could not create instance administration project. Errors: %{errors}" % { errors: result[:project].errors.full_messages })
              error(_('Could not create project'))
            end
          end

          def save_project_id(result)
            return success if project_created?

            response = application_settings.update(
              instance_administration_project_id: result[:project].id
            )

            if response
              success(result)
            else
              log_error("Could not save instance administration project ID, errors: %{errors}" % { errors: application_settings.errors.full_messages })
              error(_('Could not save project ID'))
            end
          end

          def add_group_members(result)
            group = result[:group]
            members = group.add_users(members_to_add(group), Gitlab::Access::MAINTAINER)
            errors = members.flat_map { |member| member.errors.full_messages }

            if errors.any?
              log_error('Could not add admins as members to self-monitoring project. Errors: %{errors}' % { errors: errors })
              error(_('Could not add admins as members'))
            else
              success(result)
            end
          end

          def add_prometheus_manual_configuration(result)
            return success(result) unless prometheus_enabled?
            return success(result) unless prometheus_listen_address.present?

            service = result[:project].find_or_initialize_service('prometheus')

            unless service.update(prometheus_service_attributes)
              log_error('Could not save prometheus manual configuration for self-monitoring project. Errors: %{errors}' % { errors: service.errors.full_messages })
              return error(_('Could not save prometheus manual configuration'))
            end

            success(result)
          end

          def application_settings
            @application_settings ||= ApplicationSetting.current_without_cache
          end

          def project_created?
            application_settings.instance_administration_project.present?
          end

          def parse_url(uri_string)
            Addressable::URI.parse(uri_string)
          rescue Addressable::URI::InvalidURIError, TypeError
          end

          def prometheus_enabled?
            ::Gitlab::Prometheus::Internal.prometheus_enabled?
          end

          def prometheus_listen_address
            ::Gitlab::Prometheus::Internal.listen_address
          end

          def instance_admins
            @instance_admins ||= User.admins.active
          end

          def group_owner
            instance_admins.first
          end

          def members_to_add(group)
            # Exclude admins who are already members of group because
            # `group.add_users(users)` returns an error if the users parameter contains
            # users who are already members of the group.
            instance_admins - group.members.collect(&:user)
          end

          def create_group_params
            {
              name: 'GitLab Instance Administrators',
              path: "gitlab-instance-administrators-#{SecureRandom.hex(4)}",
              visibility_level: VISIBILITY_LEVEL
            }
          end

          def docs_path
            Rails.application.routes.url_helpers.help_page_path(
              'administration/monitoring/gitlab_instance_administration_project/index'
            )
          end

          def create_project_params(group)
            {
              initialize_with_readme: true,
              visibility_level: VISIBILITY_LEVEL,
              name: PROJECT_NAME,
              description: "This project is automatically generated and will be used to help monitor this GitLab instance. [More information](#{docs_path})",
              namespace_id: group.id
            }
          end

          def internal_prometheus_listen_address_uri
            ::Gitlab::Prometheus::Internal.uri
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
  end
end
