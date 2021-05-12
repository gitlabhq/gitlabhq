# frozen_string_literal: true

module Mutations
  module MergeRequests
    class SetDraft < Base
      graphql_name 'MergeRequestSetDraft'

      argument :draft,
               GraphQL::BOOLEAN_TYPE,
               required: true,
               description: <<~DESC
                 Whether or not to set the merge request as a draft.
               DESC

      def resolve(project_path:, iid:, draft: nil)
        merge_request = authorized_find!(project_path: project_path, iid: iid)
        project = merge_request.project

        ::MergeRequests::UpdateService.new(project: project, current_user: current_user, params: { wip_event: wip_event(draft) })
          .execute(merge_request)

        {
          merge_request: merge_request,
          errors: errors_on_object(merge_request)
        }
      end

      private

      def wip_event(wip)
        wip ? 'wip' : 'unwip'
      end
    end
  end
end
