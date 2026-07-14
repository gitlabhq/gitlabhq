# frozen_string_literal: true

module Mutations
  module Issues
    class Move < Base
      graphql_name 'IssueMove'

      authorize_granular_token permissions: :move_issue,
        boundary_argument: :project_path, boundary_type: :project

      argument :target_project_path,
        GraphQL::Types::ID,
        required: true,
        description: 'Project to move the issue to.'

      argument :target_work_item_type_id,
        ::Types::GlobalIDType[::WorkItems::Type],
        required: false,
        description: 'Work item type to use in the target project. ' \
          'When omitted, the source work item type is preserved.'

      def resolve(project_path:, iid:, target_project_path:, target_work_item_type_id: nil)
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20816')

        issue = authorized_find!(project_path: project_path, iid: iid)
        target_project = resolve_project(full_path: target_project_path).sync

        move_params = {}
        move_params[:target_work_item_type_id] = target_work_item_type_id.model_id.to_i if target_work_item_type_id

        response = ::WorkItems::DataSync::MoveService.new(
          work_item: issue, current_user: current_user,
          target_namespace: target_project.project_namespace,
          params: move_params
        ).execute

        moved_issue = response.payload[:work_item] if response.success?
        errors = response.message if response.error?

        {
          issue: moved_issue,
          errors: Array.wrap(errors)
        }
      end
    end
  end
end
