# frozen_string_literal: true

module Mutations
  module WorkItems
    class Delete < BaseMutation
      graphql_name 'WorkItemDelete'
      description "Deletes a work item." \
                  " Available only when feature flag `work_items` is enabled. The feature is experimental and is subject to change without notice."

      authorize :delete_work_item

      argument :id, ::Types::GlobalIDType[::WorkItem],
               required: true,
               description: 'Global ID of the work item.'

      field :project, Types::ProjectType,
            null: true,
            description: 'Project the deleted work item belonged to.'

      def resolve(id:)
        work_item = authorized_find!(id: id)

        unless Feature.enabled?(:work_items, work_item.project)
          return { errors: ['`work_items` feature flag disabled for this project'] }
        end

        result = ::WorkItems::DeleteService.new(
          project: work_item.project,
          current_user: current_user
        ).execute(work_item)

        {
          project: result.success? ? work_item.project : nil,
          errors: result.errors
        }
      end

      private

      def find_object(id:)
        # TODO: Remove coercion when working on https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ::Types::GlobalIDType[::WorkItem].coerce_isolated_input(id)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
