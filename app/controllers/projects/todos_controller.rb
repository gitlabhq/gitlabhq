# frozen_string_literal: true

class Projects::TodosController < Projects::ApplicationController
  include Gitlab::Utils::StrongMemoize
  include TodosActions

  before_action :authenticate_user!, only: [:create]

  feature_category :notifications
  urgency :low

  private

  def issuable
    strong_memoize(:issuable) do
      case params[:issuable_type]
      when "issue"
        IssuesFinder.new(current_user, project_id: @project.id).find(params[:issuable_id])
      when "merge_request"
        MergeRequestsFinder.new(current_user, project_id: @project.id).find(params[:issuable_id])
      when "design"
        issue = IssuesFinder.new(current_user, project_id: @project.id).find(params[:issue_id])
        DesignManagement::DesignsFinder.new(issue, current_user).find(params[:issuable_id])
      end
    end
  end
end
