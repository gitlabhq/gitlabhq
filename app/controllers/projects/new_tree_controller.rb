class Projects::NewTreeController < Projects::BaseTreeController
  before_filter :require_branch_head
  before_filter :authorize_push_code!

  def show
  end

  def update
    file_path = File.join(@path, File.basename(params[:file_name]))
    result = Files::CreateService.new(@project, current_user, params, @ref, file_path).execute
    redirect_path = project_blob_path(@project, File.join(@ref, file_path))
    changes_successful_action(result, redirect_path)
  end
end
