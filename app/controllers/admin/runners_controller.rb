# frozen_string_literal: true

class Admin::RunnersController < Admin::ApplicationController
  include RunnerSetupScripts

  before_action :runner, except: [:index, :tag_list, :runner_setup_scripts]

  feature_category :runner

  def index
  end

  def show
    # We will show runner details in a read-only view in
    # future iterations. For now, this route will have a
    # redirect until this new view is developed. See more:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/347856
    redirect_to edit_admin_runner_path(runner) unless Feature.enabled?(:runner_read_only_admin_view, default_enabled: :yaml)
  end

  def edit
    assign_builds_and_projects
  end

  def update
    if Ci::UpdateRunnerService.new(@runner).update(runner_params)
      respond_to do |format|
        format.html { redirect_to edit_admin_runner_path(@runner) }
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
    @builds = runner
      .builds
      .order_id_desc
      .preload_project_and_pipeline_project.first(30)

    @projects =
      if params[:search].present?
        ::Project.search(params[:search])
      else
        Project.all
      end

    runner_projects_ids = runner.runner_projects.pluck(:project_id)
    @projects = @projects.where.not(id: runner_projects_ids) if runner_projects_ids.any?
    @projects = @projects.inc_routes
    @projects = @projects.page(params[:page]).per(30).without_count
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
