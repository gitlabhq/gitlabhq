# frozen_string_literal: true

module Mutations
  module MergeRequests
    class SetWip < Base
      graphql_name 'MergeRequestSetWip'

      argument :wip,
               GraphQL::BOOLEAN_TYPE,
               required: true,
               description: <<~DESC
                            Whether or not to set the merge request as a WIP.
                            DESC

      def resolve(project_path:, iid:, wip: nil)
        merge_request = authorized_find!(project_path: project_path, iid: iid)
        project = merge_request.project

        ::MergeRequests::UpdateService.new(project, current_user, wip_event: wip_event(merge_request, wip))
          .execute(merge_request)

        {
          merge_request: merge_request,
          errors: merge_request.errors.full_messages
        }
      end

      private

      def wip_event(merge_request, wip)
        wip ? 'wip' : 'unwip'
      end
    end
  end
end
