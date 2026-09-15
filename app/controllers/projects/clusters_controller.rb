# frozen_string_literal: true

class Projects::ClustersController < ::Clusters::ClustersController
  before_action :repository

  before_action do
    push_frontend_feature_flag(:show_gitlab_agent_feedback, type: :ops)
  end

  layout 'project'

  private

  def clusterable
    @clusterable ||= project && ClusterablePresenter.fabricate(project, current_user: current_user)
  end

  def project_path_params
    params.permit(:namespace_id, :project_id)
  end
  strong_memoize_attr :project_path_params

  def project
    @project ||= find_routable!(
      Project, File.join(project_path_params[:namespace_id], project_path_params[:project_id]), request.fullpath
    )
  end

  def repository
    @repository ||= project.repository
  end
end
