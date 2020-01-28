# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    module SelfMonitoring
      module Project
        class CreateService < ::BaseService
          include Stepable
          include SelfMonitoring::Helpers

          VISIBILITY_LEVEL = Gitlab::VisibilityLevel::INTERNAL
          PROJECT_NAME = 'GitLab self monitoring'

          steps :validate_application_settings,
            :create_group,
            :create_project,
            :save_project_id,
            :add_prometheus_manual_configuration,
            :track_event

          def initialize
            super(nil)
          end

          def execute
            execute_steps
          end

          private

          def validate_application_settings(_result)
            return success if application_settings

            log_error('No application_settings found')
            error(_('No application_settings found'))
          end

          def create_group(result)
            create_group_response =
              Gitlab::DatabaseImporters::InstanceAdministrators::CreateGroup.new.execute

            if create_group_response[:status] == :success
              success(result.merge(create_group_response))
            else
              error(create_group_response[:message])
            end
          end

          def create_project(result)
            if project_created?
              log_info('Instance administration project already exists')
              result[:project] = self_monitoring_project
              return success(result)
            end

            owner = result[:group].owners.first

            result[:project] = ::Projects::CreateService.new(owner, create_project_params(result[:group])).execute

            if result[:project].persisted?
              success(result)
            else
              log_error("Could not create instance administration project. Errors: %{errors}" % { errors: result[:project].errors.full_messages })
              error(_('Could not create project'))
            end
          end

          def save_project_id(result)
            return success(result) if project_created?

            response = application_settings.update(
              self_monitoring_project_id: result[:project].id
            )

            if response
              success(result)
            else
              log_error("Could not save instance administration project ID, errors: %{errors}" % { errors: application_settings.errors.full_messages })
              error(_('Could not save project ID'))
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

          def track_event(result)
            ::Gitlab::Tracking.event("self_monitoring", "project_created")

            success(result)
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

          def docs_path
            Rails.application.routes.url_helpers.help_page_path(
              'administration/monitoring/gitlab_self_monitoring_project/index'
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
