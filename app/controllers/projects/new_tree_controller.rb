class Projects::NewTreeController < Projects::BaseTreeController
  before_filter :authorize_show_blob_edit!
  before_filter :require_branch_head

  def show
    set_new_mr_vars
  end

  def update
    update_new_mr(Files::CreateService, file_path)
  end

  protected

  def after_edit_path
    project_blob_path(@project, @ref + file_path)
  end

  def file_path
    @file_path ||= File.join(@path, File.basename(params[:file_name]))
  end
end
