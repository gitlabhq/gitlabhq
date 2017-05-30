module Projects
  class IssueLinksController < ApplicationController
    before_action :authorize_admin_issue_link!, only: [:create, :destroy]

    def index
      render json: issues
    end

    def create
      opts = params.slice(:issue_references)
      result = IssueLinks::CreateService.new(issue, current_user, opts).execute

      render json: { result: result, issues: issues }, status: result[:http_status]
    end

    def destroy
      issue_link = IssueLink.find(params[:id])

      return render_403 unless can?(current_user, :admin_issue_link, issue_link.target.project)

      result = IssueLinks::DestroyService.new(issue_link, current_user).execute

      render json: { result: result, issues: issues }
    end

    private

    def issues
      IssueLinks::ListService.new(issue, current_user).execute
    end

    def authorize_admin_issue_link!
      render_403 unless can?(current_user, :admin_issue_link, @project)
    end

    def issue
      @issue ||=
        IssuesFinder.new(current_user, project_id: project.id)
                    .execute
                    .find_by!(iid: params[:issue_id])
    end
  end
end
