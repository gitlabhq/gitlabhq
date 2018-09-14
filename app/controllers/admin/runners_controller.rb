class Admin::RunnersController < Admin::ApplicationController
  before_action :runner, except: :index

  # rubocop: disable CodeReuse/ActiveRecord
  def index
    finder = Admin::RunnersFinder.new(params: params)
    @runners = finder.execute
<<<<<<< HEAD
    @active_runners_cnt = Ci::Runner.online.count
=======
    @active_runners_count = Ci::Runner.online.count
>>>>>>> upstream/master
    @sort = finder.sort_key
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def show
    assign_builds_and_projects
  end

  def update
    if Ci::UpdateRunnerService.new(@runner).update(runner_params)
      respond_to do |format|
        format.js
        format.html { redirect_to admin_runner_path(@runner) }
      end
    else
      assign_builds_and_projects
      render 'show'
    end
  end

  def destroy
    @runner.destroy

    redirect_to admin_runners_path, status: :found
  end

  def resume
    if Ci::UpdateRunnerService.new(@runner).update(active: true)
      redirect_to admin_runners_path, notice: 'Runner was successfully updated.'
    else
      redirect_to admin_runners_path, alert: 'Runner was not updated.'
    end
  end

  def pause
    if Ci::UpdateRunnerService.new(@runner).update(active: false)
      redirect_to admin_runners_path, notice: 'Runner was successfully updated.'
    else
      redirect_to admin_runners_path, alert: 'Runner was not updated.'
    end
  end

  private

  def runner
    @runner ||= Ci::Runner.find(params[:id])
  end

  def runner_params
    params.require(:runner).permit(Ci::Runner::FORM_EDITABLE)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def assign_builds_and_projects
    @builds = runner.builds.order('id DESC').first(30)
    @projects =
      if params[:search].present?
        ::Project.search(params[:search])
      else
        Project.all
      end

    @projects = @projects.where.not(id: runner.projects.select(:id)) if runner.projects.any?
    @projects = @projects.page(params[:page]).per(30)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
