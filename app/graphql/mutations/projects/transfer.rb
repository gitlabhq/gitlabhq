# frozen_string_literal: true

module Mutations
  module Projects
    class Transfer < BaseMutation
      graphql_name 'ProjectTransfer'

      authorize :change_namespace

      authorize_granular_token permissions: :transfer_project,
        boundary_argument: :id,
        boundary_type: :project

      argument :id,
        ::Types::GlobalIDType[::Project],
        required: true,
        description: 'Global ID of the project to transfer.'

      argument :namespace_id,
        ::Types::GlobalIDType[::Namespace],
        required: true,
        description: 'Global ID of the target namespace.'

      field :project,
        Types::ProjectType,
        null: true,
        description: 'Project after mutation.'

      def resolve(id:, namespace_id:)
        project = authorized_find!(id)
        namespace = find_object(namespace_id)&.sync

        if namespace.is_a?(::Namespaces::ProjectNamespace)
          error = 'Target namespace must be a group or user namespace, not a project namespace.'
          return { project: project, errors: [error] }
        end

        service = ::Projects::TransferService.new(project, current_user)

        if Feature.enabled?(:groups_and_projects_async_transfer, project.root_ancestor)
          async_transfer(service, project, namespace)
        else
          sync_transfer(service, project, namespace)
        end
      end

      private

      def async_transfer(service, project, namespace)
        result = service.schedule_async_transfer(namespace)

        if result.success?
          { project: project, errors: [] }
        else
          { project: project, errors: [result.message] }
        end
      end

      def sync_transfer(service, project, namespace)
        # The synchronous transfer path issues more queries than the default threshold
        # allows. Mirrors the existing exemption for the REST transfer action.
        # See app/controllers/projects_controller.rb#disable_transfer_query_limiting.
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/work_items/606043', new_threshold: 110)

        if service.execute(namespace)
          { project: project, errors: [] }
        else
          errors = project.errors[:new_namespace].presence || ['Transfer failed']
          { project: project, errors: errors }
        end
      end

      def find_object(id)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end

Mutations::Projects::Transfer.prepend_mod_with('Mutations::Projects::Transfer')
