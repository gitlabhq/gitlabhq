# frozen_string_literal: true

class Groups::CrmController < Groups::ApplicationController
  feature_category :team_planning

  before_action :authorize_read_crm_contact!, only: [:contacts]
  before_action :authorize_read_crm_organization!, only: [:organizations]

  def contacts
    respond_to do |format|
      format.html
    end
  end

  def organizations
    respond_to do |format|
      format.html
    end
  end

  private

  def authorize_read_crm_contact!
    render_404 unless can?(current_user, :read_crm_contact, group)
  end

  def authorize_read_crm_organization!
    render_404 unless can?(current_user, :read_crm_organization, group)
  end
end
