module Projects
  class RelatedIssuesController < ApplicationController
    include IssuesHelper

    before_action :authorize_read_related_issue!
    before_action :authorize_admin_related_issue!, only: [:create]

    def index
      render json: serialize_as_json
    end

    def create
      opts = { issue_references: params[:issue_references] }
      result = CreateRelatedIssueService.new(issue, current_user, opts).execute

      render json: result, status: result['http_status']
    end

    private

    def authorize_admin_related_issue!
      return render_404 unless can?(current_user, :admin_related_issue, @project)
    end

    def authorize_read_related_issue!
      return render_404 unless can?(current_user, :read_related_issue, @project)
    end

    # TODO: Move to service class
    def serialize_as_json
      related_issues.map do |related_issue|
        referenced_issue = related_issue.related_issue == issue ? related_issue.issue : related_issue.related_issue

        {
          title: referenced_issue.title,
          state: referenced_issue.state,
          reference: referenced_issue.to_reference(@project),
          path: url_for_issue(referenced_issue.iid, @project, only_path: true),
        }
      end
    end

    def related_issues
      RelatedIssue
        .where("issue_id = #{issue.id} OR related_issue_id = #{issue.id}")
        .preload(:related_issue, :issue)
        .order(:created_at)
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
