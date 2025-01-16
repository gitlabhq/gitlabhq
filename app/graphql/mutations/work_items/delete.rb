# frozen_string_literal: true

module Mutations
  module WorkItems
    class Delete < BaseMutation
      graphql_name 'WorkItemDelete'
      description "Deletes a work item."

      authorize :delete_work_item

      argument :id, ::Types::GlobalIDType[::WorkItem],
        required: true,
        description: 'Global ID of the work item.'

      field :project, ::Types::ProjectType,
        null: true,
        description: 'Project the deleted work item belonged to.',
        deprecated: {
          reason: 'Use `namespace`',
          milestone: '16.9'
        }

      field :namespace, ::Types::NamespaceType,
        null: true,
        description: 'Namespace the deleted work item belonged to.'

      def resolve(id:)
        work_item = authorized_find!(id: id)

        result = ::WorkItems::DeleteService.new(
          container: work_item.resource_parent,
          current_user: current_user
        ).execute(work_item)

        response = { errors: result.errors }

        if result.success?
          response.merge(project: work_item.project, namespace: work_item.namespace)
        else
          response
        end
      end
    end
  end
end
