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
          required: false,
          description: 'IDs of excluded projects.'

        argument :group_ids,
          [::Types::GlobalIDType[::Group]],
          required: false,
          description: 'IDs of excluded groups.'

        authorize :admin_all_resources

        def resolve(integration_name:, project_ids: [], group_ids: [])
          authorize!(:global)

          result = ::Integrations::Exclusions::DestroyService.new(
            current_user: current_user,
            projects: projects(project_ids),
            groups: groups(group_ids),
            integration_name: integration_name
          ).execute

          exclusions = result.payload

          # Integrations::Exclusions::DestroyService calls destroy_all in some circumstances which returns a frozen
          # array.  We call dup here to allow entries to be redacted by field extensions.
          exclusions = exclusions.dup if exclusions.frozen?
          {
            exclusions: exclusions,
            errors: result.errors
          }
        end

        private

        def projects(project_ids)
          return [] unless project_ids.present?

          Project.id_in(resolve_ids(project_ids))
        end

        def groups(group_ids)
          return [] unless group_ids.present?

          Group.id_in(resolve_ids(group_ids))
        end
      end
    end
  end
end
