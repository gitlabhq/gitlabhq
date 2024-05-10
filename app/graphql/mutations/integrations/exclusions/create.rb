# frozen_string_literal: true

module Mutations
  module Integrations
    module Exclusions
      class Create < BaseMutation
        graphql_name 'IntegrationExclusionCreate'
        include ResolvesIds

        field :exclusions, [::Types::Integrations::ExclusionType],
          null: true,
          description: 'Integration exclusions created by the mutation.'

        argument :integration_name,
          ::Types::Integrations::IntegrationTypeEnum,
          required: true,
          description: 'Type of integration to exclude.'

        argument :project_ids,
          [::Types::GlobalIDType[::Project]],
          required: true,
          description: 'Ids of projects to exclude.'

        authorize :admin_all_resources

        def resolve(integration_name:, project_ids:)
          authorize!(:global)

          projects = Project.id_in(resolve_ids(project_ids))

          result = ::Integrations::Exclusions::CreateService.new(
            current_user: current_user,
            projects: projects,
            integration_name: integration_name
          ).execute

          {
            exclusions: result.payload,
            errors: result.errors
          }
        end
      end
    end
  end
end
