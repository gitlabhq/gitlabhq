module Projects
  class RelatedIssuesController < ApplicationController
    include IssuesHelper

    before_action :authorize_read_issue!, only: [:index]

    def index
      render json: serialize_as_json
    end

    def create
    end

    private

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
