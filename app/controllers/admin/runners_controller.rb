# frozen_string_literal: true

class Admin::RunnersController < Admin::ApplicationController
  include RunnerSetupScripts

  before_action :runner, only: [:show, :edit, :register, :update]

  feature_category :runner
  urgency :low

  def index; end

  def show; end

  def edit
    assign_projects
  end

  def new; end

  def register
    render_404 unless runner.registration_available?
  end

  def update
    if Ci::Runners::UpdateRunnerService.new(@runner).execute(runner_params).success?
      respond_to do |format|
        format.html { redirect_to edit_admin_runner_path(@runner) }
      end
    else
      assign_projects
      render 'show'
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
  def assign_projects
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

Admin::RunnersController.prepend_mod
