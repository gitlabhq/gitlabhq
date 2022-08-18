# frozen_string_literal: true

class Admin::RunnerProjectsController < Admin::ApplicationController
  before_action :project, only: [:create]

  feature_category :runner
  urgency :low

  def create
    @runner = Ci::Runner.find(params[:runner_project][:runner_id])

    if ::Ci::Runners::AssignRunnerService.new(@runner, @project, current_user).execute.success?
      redirect_to edit_admin_runner_url(@runner), notice: s_('Runners|Runner assigned to project.')
    else
      redirect_to edit_admin_runner_url(@runner), alert: 'Failed adding runner to project'
    end
  end

  def destroy
    rp = Ci::RunnerProject.find(params[:id])
    runner = rp.runner

    ::Ci::Runners::UnassignRunnerService.new(rp, current_user).execute

    redirect_to edit_admin_runner_url(runner), status: :found, notice: s_('Runners|Runner unassigned from project.')
  end

  private

  def project
    @project = Project.find_by_full_path(
      [params[:namespace_id], '/', params[:project_id]].join('')
    )
    @project || render_404
  end
end
