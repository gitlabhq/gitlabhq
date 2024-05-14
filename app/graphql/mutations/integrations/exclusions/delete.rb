# frozen_string_literal: true

module Mutations
  module Integrations
    module Exclusions
      class Delete < BaseMutation
        graphql_name 'IntegrationExclusionDelete'
        include ResolvesIds

        field :exclusions, [::Types::Integrations::ExclusionType],
          null: true,
          description: 'Project no longer excluded due to the mutation.'

        argument :integration_name,
          ::Types::Integrations::IntegrationTypeEnum,
          required: true,
          description: 'Type of integration.'

        argument :project_ids,
          [::Types::GlobalIDType[::Project]],
          required: true,
          description: 'IDs of excluded projects.'

        authorize :admin_all_resources

        def resolve(integration_name:, project_ids:)
          authorize!(:global)

          projects = Project.id_in(resolve_ids(project_ids))

          result = ::Integrations::Exclusions::DestroyService.new(
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
