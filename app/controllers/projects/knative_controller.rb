class Projects::KnativeController < Projects::ApplicationController
  respond_to :html

  before_action :authorize_read_cluster!
  before_action :serverless_function, only: [:edit, :update, :destroy]

  def index
  end

  def index
    @serverless_functions = project.serverless_functions
  end

  def new
    @serverless_function = project.serverless_functions.new
  end

  def create
    @serverless_function = project.serverless_functions.create(create_params)

    if @serverless_function.persisted?
      flash[:notice] = 'Function was successfully created.'
      redirect_to project_knative_index_path(@project)
    else
      render :new
    end
  end

  def edit
  end

  def update
    if serverless_function.update(update_params)
      flash[:notice] = 'Function was successfully updated.'
      redirect_to project_knative_index_path(@project)
    else
      render :edit
    end
  end  
  
  def destroy
    if serverless_function.destroy
      flash[:notice] = 'Function was successfully updated.'
      redirect_to project_knative_index_path(@project)
    else
      flash[:notice] = 'Function was not removed.'
      redirect_to project_knative_index_path(@project)
    end
  end

  protected

  def serverless_function
    @serverless_function ||= project.serverless_functions.find(params[:id])
  end

  def create_params
    params.require(:serverless_functions)
          .permit(:name, :function_code, :runtime_image, :active)
  end

  def update_params
    params.require(:serverless_functions)
          .permit(:name, :function_code, :runtime_image)
  end

end
