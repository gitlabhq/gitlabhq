class Projects::NewTreeController < Projects::ApplicationController
  include ExtractsPath

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def show
  end

  def update
    result = Files::CreateContext.new(@project, current_user, params, @ref, @path).execute

    if result[:status] == :success
      flash[:notice] = "Your changes have been successfully commited"
      redirect_to project_blob_path(@project, File.join(@id, params[:file_name]))
    else
      flash[:alert] = result[:error]
      render :show
    end
  end
end
