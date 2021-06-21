# frozen_string_literal: true

class Admin::RunnersController < Admin::ApplicationController
  include RunnerSetupScripts

  before_action :runner, except: [:index, :tag_list, :runner_setup_scripts]
  before_action only: [:index] do
    push_frontend_feature_flag(:runner_list_view_vue_ui, current_user, default_enabled: :yaml)
  end

  feature_category :runner

  NUMBER_OF_RUNNERS_PER_PAGE = 30

  def index
    finder = Ci::RunnersFinder.new(current_user: current_user, params: params)
    @runners = finder.execute.page(params[:page]).per(NUMBER_OF_RUNNERS_PER_PAGE)
    @active_runners_count = Ci::Runner.online.count
    @sort = finder.sort_key
  end

  def show
    assign_builds_and_projects
  end

  def update
    if Ci::UpdateRunnerService.new(@runner).update(runner_params)
      respond_to do |format|
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
      redirect_to admin_runners_path, notice: _('Runner was successfully updated.')
    else
      redirect_to admin_runners_path, alert: _('Runner was not updated.')
    end
  end

  def pause
    if Ci::UpdateRunnerService.new(@runner).update(active: false)
      redirect_to admin_runners_path, notice: _('Runner was successfully updated.')
    else
      redirect_to admin_runners_path, alert: _('Runner was not updated.')
    end
  end

  def tag_list
    tags = Autocomplete::ActsAsTaggableOn::TagsFinder.new(params: params).execute

    render json: ActsAsTaggableOn::TagSerializer.new.represent(tags)
  end

  def runner_setup_scripts
    private_runner_setup_scripts
  end

  private

  def runner
    @runner ||= Ci::Runner.find(params[:id])
  end

  def runner_params
    params.require(:runner).permit(permitted_attrs)
  end

  def permitted_attrs
    if Gitlab.com?
      Ci::Runner::FORM_EDITABLE + Ci::Runner::MINUTES_COST_FACTOR_FIELDS
    else
      Ci::Runner::FORM_EDITABLE
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def assign_builds_and_projects
    @builds = runner.builds.order('id DESC').preload_project_and_pipeline_project.first(30)
    @projects =
      if params[:search].present?
        ::Project.search(params[:search])
      else
        Project.all
      end

    @projects = @projects.where.not(id: runner.projects.select(:id)) if runner.projects.any?
    @projects = @projects.inc_routes
    @projects = @projects.page(params[:page]).per(30).without_count
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
