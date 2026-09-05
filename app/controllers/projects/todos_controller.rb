# frozen_string_literal: true

class Projects::TodosController < Projects::ApplicationController
  include Gitlab::Utils::StrongMemoize
  include TodosActions

  before_action :authenticate_user!, only: [:create]

  feature_category :notifications
  urgency :low

  private

  def issuable_params
    params.permit(:issuable_type, :issuable_id, :issue_id)
  end
  strong_memoize_attr :issuable_params

  def issuable
    strong_memoize(:issuable) do
      case issuable_params[:issuable_type]
      when "issue"
        IssuesFinder.new(current_user, project_id: @project.id).find(issuable_params[:issuable_id])
      when "merge_request"
        MergeRequestsFinder.new(current_user, project_id: @project.id).find(issuable_params[:issuable_id])
      when "design"
        issue = IssuesFinder.new(current_user, project_id: @project.id).find(issuable_params[:issue_id])
        DesignManagement::DesignsFinder.new(issue, current_user).find(issuable_params[:issuable_id])
      end
    end
  end
end
