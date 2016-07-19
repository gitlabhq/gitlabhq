class Projects::RunnersController < Projects::ApplicationController
  before_action :authorize_admin_build!
  before_action :set_runner, only: [:edit, :update, :destroy, :pause, :resume, :show]

  layout 'project_settings'

  def index
    @project_runners = project.runners.ordered
    @assignable_runners = current_user.ci_authorized_runners.
      assignable_for(project).ordered.page(params[:page]).per(20)
    @shared_runners = Ci::Runner.shared.active
    @shared_runners_count = @shared_runners.count(:all)
  end

  def edit
  end

  def update
    if @runner.update_attributes(runner_params)
      redirect_to runner_path(@runner), notice: 'Runner was successfully updated.'
    else
      render 'edit'
    end
  end

  def destroy
    if @runner.only_for?(project)
      @runner.destroy
    end

    redirect_to runners_path(@project)
  end

  def resume
    if @runner.update_attributes(active: true)
      redirect_to runner_path(@runner), notice: 'Runner was successfully updated.'
    else
      redirect_to runner_path(@runner), alert: 'Runner was not updated.'
    end
  end

  def pause
    if @runner.update_attributes(active: false)
      redirect_to runner_path(@runner), notice: 'Runner was successfully updated.'
    else
      redirect_to runner_path(@runner), alert: 'Runner was not updated.'
    end
  end

  def show
  end

  def toggle_shared_runners
    project.toggle!(:shared_runners_enabled)

    redirect_to namespace_project_runners_path(project.namespace, project)
  end

  protected

  def set_runner
    @runner ||= project.runners.find(params[:id])
  end

  def runner_params
    params.require(:runner).permit(Ci::Runner::FORM_EDITABLE)
  end
end
