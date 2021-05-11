# frozen_string_literal: true

module Mutations
  module AlertManagement
    module HttpIntegration
      class Create < HttpIntegrationBase
        include FindsProject

        graphql_name 'HttpIntegrationCreate'

        argument :project_path, GraphQL::ID_TYPE,
                 required: true,
                 description: 'The project to create the integration in.'

        argument :name, GraphQL::STRING_TYPE,
                 required: true,
                 description: 'The name of the integration.'

        argument :active, GraphQL::BOOLEAN_TYPE,
                 required: true,
                 description: 'Whether the integration is receiving alerts.'

        def resolve(args)
          project = authorized_find!(args[:project_path])

          response ::AlertManagement::HttpIntegrations::CreateService.new(
            project,
            current_user,
            http_integration_params(project, args)
          ).execute
        end
      end
    end
  end
end

Mutations::AlertManagement::HttpIntegration::Create.prepend_mod_with('Mutations::AlertManagement::HttpIntegration::Create')
