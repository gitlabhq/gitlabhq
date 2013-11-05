class Projects::NewTreeController < Projects::ApplicationController
  include ExtractsPath

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  before_filter :create_requirements, only: [:show, :update]

  def show
  end

  def update
    file_name = params[:file_name]

    unless file_name =~ Gitlab::Regex.path_regex
      flash[:notice] = "Your changes could not be commited, because file name contains not allowed characters"
      render :show and return
    end

    file_path = if @path.blank?
                  file_name
                else
                  File.join(@path, file_name)
                end

    blob = @repository.blob_at(@commit.id, file_path)

    if blob
      flash[:notice] = "Your changes could not be commited, because file with such name exists"
      render :show and return
    end

    new_file_action = Gitlab::Satellite::NewFileAction.new(current_user, @project, @ref, @path)
    updated_successfully = new_file_action.commit!(
      params[:content],
      params[:commit_message],
      file_name,
    )

    if updated_successfully
      redirect_to project_blob_path(@project, File.join(@id, params[:file_name])), notice: "Your changes have been successfully commited"
    else
      flash[:notice] = "Your changes could not be commited, because the file has been changed"
      render :show
    end
  end

  private

  def create_requirements
    allowed = if project.protected_branch? @ref
                can?(current_user, :push_code_to_protected_branches, project)
              else
                can?(current_user, :push_code, project)
              end

    return access_denied! unless allowed

    unless @repository.branch_names.include?(@ref)
      redirect_to project_blob_path(@project, @id), notice: "You can only create files if you are on top of a branch"
    end
  end
end
