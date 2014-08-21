class Projects::NewTreeController < Projects::BaseTreeController
  before_filter :require_branch_head
  before_filter :authorize_push!

  def show
  end

  def update
    file_path = File.join(@path, File.basename(params[:file_name]))
    result = Projects::Repositories::CreateFile.perform(project: @project,
                                                        user: current_user,
                                                        params: params,
                                                        ref: @ref,
                                                        path: file_path)

    if result.success?
      flash[:notice] = "Your changes have been successfully committed"
      redirect_to project_blob_path(@project, File.join(@ref, file_path))
    else
      flash[:alert] = result[:error]
      render :show
    end
  end
end
