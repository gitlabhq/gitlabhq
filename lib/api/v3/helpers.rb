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

      # project helpers

      def filter_projects(projects)
        if params[:membership]
          projects = projects.merge(current_user.authorized_projects)
        end

        if params[:owned]
          projects = projects.merge(current_user.owned_projects)
        end

        if params[:starred]
          projects = projects.merge(current_user.starred_projects)
        end

        if params[:search].present?
          projects = projects.search(params[:search])
        end

        if params[:visibility].present?
          projects = projects.where(visibility_level: Gitlab::VisibilityLevel.level_value(params[:visibility]))
        end

        unless params[:archived].nil?
          projects = projects.where(archived: to_boolean(params[:archived]))
        end

        projects.reorder(params[:order_by] => params[:sort])
      end
    end
  end
end
