# frozen_string_literal: true

class Groups::Crm::OrganizationsController < Groups::ApplicationController
  feature_category :team_planning
  urgency :low

  before_action :validate_crm_group!
  before_action :authorize_read_crm_organization!

  def new
    render action: "index"
  end

  def edit
    render action: "index"
  end

  private

  def authorize_read_crm_organization!
    render_404 unless can?(current_user, :read_crm_organization, group)
  end
end
