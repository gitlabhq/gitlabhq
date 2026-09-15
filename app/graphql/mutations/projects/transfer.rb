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
        result = service.schedule_async_transfer(namespace)

        if result.success?
          { project: project, errors: [] }
        else
          { project: project, errors: [result.message] }
        end
      end

      private

      def find_object(id)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end

Mutations::Projects::Transfer.prepend_mod_with('Mutations::Projects::Transfer')
