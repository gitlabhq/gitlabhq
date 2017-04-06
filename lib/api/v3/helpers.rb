module API
  module V3
    module Helpers
      def find_project_issue(id)
        IssuesFinder.new(current_user, project_id: user_project.id).find(id)
      end

      def find_project_merge_request(id)
        MergeRequestsFinder.new(current_user, project_id: user_project.id).find(id)
      end

      def find_merge_request_with_access(id, access_level = :read_merge_request)
        merge_request = user_project.merge_requests.find(id)
        authorize! access_level, merge_request
        merge_request
      end

      def convert_parameters_from_legacy_format(params)
        if params[:assignee_id].present?
          params[:assignee_ids] = [params.delete(:assignee_id)]
        end

        params
      end
    end
  end
end
