# frozen_string_literal: true

module Mutations
  module AlertManagement
    module HttpIntegration
      class Create < HttpIntegrationBase
        include ResolvesProject

        graphql_name 'HttpIntegrationCreate'

        argument :project_path, GraphQL::ID_TYPE,
                 required: true,
                 description: 'The project to create the integration in'

        argument :name, GraphQL::STRING_TYPE,
                 required: true,
                 description: 'The name of the integration'

        argument :active, GraphQL::BOOLEAN_TYPE,
                 required: true,
                 description: 'Whether the integration is receiving alerts'

        def resolve(args)
          project = authorized_find!(full_path: args[:project_path])

          response ::AlertManagement::HttpIntegrations::CreateService.new(
            project,
            current_user,
            args.slice(:name, :active)
          ).execute
        end

        private

        def find_object(full_path:)
          resolve_project(full_path: full_path)
        end
      end
    end
  end
end
