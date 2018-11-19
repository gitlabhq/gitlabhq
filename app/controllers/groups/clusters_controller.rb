# frozen_string_literal: true

class Groups::ClustersController < Clusters::ClustersController
  include ControllerWithCrossProjectAccessCheck

  prepend_before_action :check_group_clusters_feature_flag!
  prepend_before_action :group
  requires_cross_project_access

  layout 'group'

  private

  def clusterable
    @clusterable ||= ClusterablePresenter.fabricate(group, current_user: current_user)
  end

  def group
    @group ||= find_routable!(Group, params[:group_id] || params[:id])
  end

  def check_group_clusters_feature_flag!
    render_404 unless Feature.enabled?(:group_clusters)
  end
end
