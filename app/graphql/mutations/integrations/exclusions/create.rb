# frozen_string_literal: true

module Mutations
  module Integrations
    module Exclusions
      class Create < BaseMutation
        graphql_name 'IntegrationExclusionCreate'
        include ResolvesIds

        MAX_PROJECT_IDS = ::Integrations::Exclusions::CreateService::MAX_PROJECTS
        MAX_GROUP_IDS = ::Integrations::Exclusions::CreateService::MAX_GROUPS

        field :exclusions, [::Types::Integrations::ExclusionType],
          null: true,
          description: 'Integration exclusions created by the mutation.'

        argument :integration_name,
          ::Types::Integrations::IntegrationTypeEnum,
          required: true,
          description: 'Type of integration to exclude.'

        argument :project_ids,
          [::Types::GlobalIDType[::Project]],
          required: false,
          validates: { length: { maximum: MAX_PROJECT_IDS } },
          description: "IDs of projects to exclude up to a maximum of #{MAX_PROJECT_IDS}."

        argument :group_ids,
          [::Types::GlobalIDType[::Group]],
          required: false,
          validates: { length: { maximum: MAX_GROUP_IDS } },
          description: "IDs of groups to exclude up to a maximum of #{MAX_GROUP_IDS}."

        authorize :admin_all_resources

        def resolve(integration_name:, project_ids: [], group_ids: [])
          authorize!(:global)

          result = ::Integrations::Exclusions::CreateService.new(
            current_user: current_user,
            projects: projects(project_ids),
            groups: groups(group_ids),
            integration_name: integration_name
          ).execute

          {
            exclusions: result.payload,
            errors: result.errors
          }
        end

        private

        def groups(group_ids)
          return [] unless group_ids.present?

          Group.id_in(resolve_ids(group_ids)).limit(MAX_GROUP_IDS)
        end

        def projects(project_ids)
          return [] unless project_ids.present?

          Project.id_in(resolve_ids(project_ids)).with_group.limit(MAX_PROJECT_IDS)
        end
      end
    end
  end
end
