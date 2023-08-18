# frozen_string_literal: true

module Mutations
  module AlertManagement
    module PrometheusIntegration
      class Create < PrometheusIntegrationBase
        graphql_name 'PrometheusIntegrationCreate'

        include FindsProject

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Project to create the integration in.'

        argument :active, GraphQL::Types::Boolean,
          required: true,
          description: 'Whether the integration is receiving alerts.'

        argument :api_url, GraphQL::Types::String,
          required: false,
          description: 'Endpoint at which Prometheus can be queried.'

        def resolve(args)
          project = authorized_find!(args[:project_path])

          return integration_exists if project.prometheus_integration

          result = ::Projects::Operations::UpdateService.new(
            project,
            current_user,
            **integration_attributes(args),
            **token_attributes
          ).execute

          response(project.prometheus_integration, result)
        end

        private

        def integration_exists
          response(nil, message: _('Multiple Prometheus integrations are not supported'))
        end
      end
    end
  end
end
