# frozen_string_literal: true

class Groups::Clusters::IntegrationsController < Clusters::IntegrationsController
  include ControllerWithCrossProjectAccessCheck

  prepend_before_action :group
  requires_cross_project_access

  private

  def clusterable
    @clusterable ||= ClusterablePresenter.fabricate(group, current_user: current_user)
  end

  def group
    @group ||= find_routable!(Group, params[:group_id] || params[:id])
  end
end
