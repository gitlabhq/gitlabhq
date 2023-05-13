# frozen_string_literal: true

# NOTE: This controller does not inherit from JiraConnect::ApplicationController
# because we don't receive a JWT for this action, so we rely on standard GitLab authentication.
class JiraConnect::BranchesController < ApplicationController
  feature_category :integrations

  def new
    @new_branch_data = new_branch_data
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
