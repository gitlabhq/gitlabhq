# frozen_string_literal: true

class Projects::ClustersController < Clusters::ClustersController
  prepend_before_action :project
  before_action :repository

  before_action do
    push_frontend_feature_flag(:prometheus_computed_alerts)
  end

  layout 'project'

  private

  def clusterable
    @clusterable ||= ClusterablePresenter.fabricate(project, current_user: current_user)
  end

  def project
    @project ||= find_routable!(Project, File.join(params[:namespace_id], params[:project_id]))
  end

  def repository
    @repository ||= project.repository
  end

  def metrics_dashboard_params
    params.permit(:embedded, :group, :title, :y_label).merge(
      {
        cluster: cluster,
        cluster_type: :project
      }
    )
  end
end
