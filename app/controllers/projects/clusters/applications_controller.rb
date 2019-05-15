# frozen_string_literal: true

class Projects::Clusters::ApplicationsController < Clusters::ApplicationsController
  prepend_before_action :project

  private

  def clusterable
    @clusterable ||= ClusterablePresenter.fabricate(project, current_user: current_user)
  end

  def project
    @project ||= find_routable!(Project, File.join(params[:namespace_id], params[:project_id]))
  end
end
