class Projects::FeatureFlagsController < Projects::ApplicationController
  respond_to :html

  before_action :authorize_read_feature_flag!
  before_action :authorize_update_feature_flag!, only: [:edit, :update]
  before_action :authorize_destroy_feature_flag!, only: [:destroy]

  before_action :feature_flag, only: [:edit, :update, :destroy]

  def index
    @feature_flags = project.operations_feature_flags
      .ordered
      .page(params[:page]).per(30)
  end

  def new
    @feature_flag = project.operations_feature_flags.new
  end

  def create
    @feature_flag = project.operations_feature_flags.create(create_params)

    if @feature_flag.persisted?
      redirect_to project_feature_flags_path(@project), status: 302, notice: 'Feature flag was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if feature_flag.update(update_params)
      redirect_to project_feature_flags_path(@project), status: 302, notice: 'Feature flag was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    if feature_flag.destroy
      redirect_to project_feature_flags_path(@project), status: 302, notice: 'Feature flag was successfully removed.'
    else
      redirect_to project_feature_flags_path(@project), status: 302, alert: 'Feature flag was not removed.'
    end
  end

  protected

  def feature_flag
    @feature_flag ||= project.operations_feature_flags.find(params[:id])
  end

  def create_params
    params.require(:operations_feature_flag)
          .permit(:name, :description, :active)
  end

  def update_params
    params.require(:operations_feature_flag)
          .permit(:name, :description, :active)
  end
end
