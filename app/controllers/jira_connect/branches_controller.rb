# frozen_string_literal: true

class JiraConnect::BranchesController < JiraConnect::ApplicationController
  before_action :authenticate_user!, only: :new
  skip_before_action :verify_atlassian_jwt!, only: :new

  def new
    @new_branch_data = new_branch_data
  end

  # If the GitLab for Jira Cloud app was installed from the Jira marketplace and points to a self-managed instance,
  # we route the user to the self-managed instance, otherwise we redirect to :new
  def route
    if current_jira_installation.proxy?
      redirect_to "#{current_jira_installation.create_branch_url}?#{request.query_string}"

      return
    end

    redirect_to "#{new_jira_connect_branch_path}?#{request.query_string}"
  end

  private

  def initial_branch_name
    return unless params[:issue_key].present?

    Issue.to_branch_name(
      params[:issue_key],
      params[:issue_summary]
    )
  end

  def new_branch_data
    {
      initial_branch_name: initial_branch_name,
      success_state_svg_path:
        ActionController::Base.helpers.image_path('illustrations/empty-state/empty-merge-requests-md.svg')
    }
  end
end
