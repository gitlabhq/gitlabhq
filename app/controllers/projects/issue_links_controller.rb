# frozen_string_literal: true

module Projects
  class IssueLinksController < Projects::ApplicationController
    include IssuableLinks

    before_action :authorize_admin_issue_link!, only: [:create, :destroy]
    before_action :authorize_issue_link_association!, only: :destroy
    before_action :disable_query_limit!, only: :create

    feature_category :team_planning
    urgency :low

    private

    def disable_query_limit!
      Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/467087')
    end

    def authorize_admin_issue_link!
      render_403 unless can?(current_user, :admin_issue_link, issue)
    end

    def authorize_issue_link_association!
      render_404 if link.target != issue && link.source != issue
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def issue
      @issue ||=
        IssuesFinder.new(current_user, project_id: @project.id)
                    .find_by!(iid: params[:issue_id])
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def list_service
      IssueLinks::ListService.new(issue, current_user)
    end

    def create_service
      IssueLinks::CreateService.new(issue, current_user, create_params)
    end

    def destroy_service
      IssueLinks::DestroyService.new(link, current_user)
    end

    def link
      @link ||= IssueLink.find(params[:id])
    end

    def create_params
      params.permit(:link_type, issuable_references: [])
    end
  end
end
