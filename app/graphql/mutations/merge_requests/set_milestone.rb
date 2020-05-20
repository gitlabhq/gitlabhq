# frozen_string_literal: true

module Mutations
  module MergeRequests
    class SetMilestone < Base
      graphql_name 'MergeRequestSetMilestone'

      argument :milestone_id,
               GraphQL::ID_TYPE,
               required: false,
               loads: Types::MilestoneType,
               description: <<~DESC
                            The milestone to assign to the merge request.
               DESC

      def resolve(project_path:, iid:, milestone: nil)
        merge_request = authorized_find!(project_path: project_path, iid: iid)
        project = merge_request.project

        ::MergeRequests::UpdateService.new(project, current_user, milestone: milestone)
          .execute(merge_request)

        {
          merge_request: merge_request,
          errors: errors_on_object(merge_request)
        }
      end
    end
  end
end
