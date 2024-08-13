# frozen_string_literal: true

class Groups::ClustersController < ::Clusters::ClustersController
  include ControllerWithCrossProjectAccessCheck

  before_action :ensure_feature_enabled!
  requires_cross_project_access

  layout 'group'

  private

  def clusterable
    @clusterable ||= group && ClusterablePresenter.fabricate(group, current_user: current_user)
  end

  def group
    @group ||= find_routable!(Group, params[:group_id] || params[:id], request.fullpath)
  end
end
