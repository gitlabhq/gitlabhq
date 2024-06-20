# frozen_string_literal: true

module Mutations
  module Integrations
    module Exclusions
      class Create < BaseMutation
        graphql_name 'IntegrationExclusionCreate'
        include ResolvesIds
        MAX_PROJECT_IDS = ::Integrations::Exclusions::CreateService::MAX_PROJECTS

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
          description: "IDs of projects to exclude up to a maximum of #{MAX_PROJECT_IDS}."

        authorize :admin_all_resources

        def resolve(integration_name:, project_ids:)
          authorize!(:global)

          if project_ids.length > MAX_PROJECT_IDS
            raise Gitlab::Graphql::Errors::ArgumentError, "Count of projectIds should be less than #{MAX_PROJECT_IDS}"
          end

          projects = Project.id_in(resolve_ids(project_ids)).with_group.limit(MAX_PROJECT_IDS)

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
