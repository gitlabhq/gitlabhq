module Projects
  class RelatedIssuesController < ApplicationController
    before_action :authorize_read_related_issue!
    before_action :authorize_admin_related_issue!, only: [:create, :destroy]

    def index
      render json: issues
    end

    def create
      opts = { issue_references: params[:issue_references] }
      result = RelatedIssues::CreateService.new(issue, current_user, opts).execute

      if result['status'] == :success
        render json: { result: result, issues: issues }, status: result['http_status']
      else
        render json: { result: result }, status: result['http_status']
      end
    end

    def destroy
      related_issue = RelatedIssue.find(params[:id])

      # In order to remove a given relation, one must be allowed to admin_related_issue both the current
      # project and on the related issue project.
      return render_404 unless can?(current_user, :admin_related_issue, related_issue.related_issue.project)

      result = RelatedIssues::DestroyService.new(related_issue, current_user).execute

      render json: { result: result, issues: issues }
    end

    private

    def issues
      RelatedIssues::ListService.new(issue, current_user).execute
    end

    def authorize_admin_related_issue!
      return render_404 unless can?(current_user, :admin_related_issue, @project)
    end

    def authorize_read_related_issue!
      return render_404 unless can?(current_user, :read_related_issue, @project)
    end

    def issue
      @issue ||=
        IssuesFinder.new(current_user, project_id: project.id)
                    .execute
                    .where(iid: params[:issue_id])
                    .first!
    end
  end
end
