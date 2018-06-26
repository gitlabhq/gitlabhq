class Projects::FeatureFlagsController < Projects::ApplicationController
  respond_to :html

  before_action :authorize_read_feature_flags!
  before_action :authorize_update_feature_flags!, only: [:edit, :update]
  before_action :authorize_admin_feature_flags!, only: [:destroy]

  before_action :feature_flag, only: [:edit, :update, :destroy]

  def index
    @feature_flags = project.project_feature_flags
    @unleash_instanceid = project.project_feature_flags_access_tokens.first&.token || project.project_feature_flags_access_tokens.create!.token
  end

  def new
    @feature_flag = project.project_feature_flags.new
  end

  def create
    @feature_flag = project.project_feature_flags.create(create_params)

    if @feature_flag.persisted?
      flash[:notice] = 'Feature flag was successfully created.'
      redirect_to project_feature_flags_path(@project)
    else
      render :new
    end
  end

  def edit
  end

  def update
    if feature_flag.update(update_params)
      flash[:notice] = 'Feature flag was successfully updated.'
      redirect_to project_feature_flags_path(@project)
    else
      render :edit
    end
  end

  protected

  def feature_flag
    @feature_flag ||= project.project_feature_flags.find(params[:id])
  end

  def create_params
    params.require(:project_feature_flag)
          .permit(:name, :description, :active)
  end

  def update_params
    params.require(:project_feature_flag)
          .permit(:description, :active)
  end
end
