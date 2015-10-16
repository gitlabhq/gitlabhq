# Controller for viewing a repository's file structure
class Projects::TreeController < Projects::ApplicationController
  include ExtractsPath
  include ActionView::Helpers::SanitizeHelper

  before_action :require_non_empty_project, except: [:new, :create]
  before_action :assign_ref_vars
  before_action :assign_dir_vars, only: [:create_dir]
  before_action :authorize_download_code!
  before_action :authorize_push_code!, only: [:create_dir]

  def show
    return render_404 unless @repository.commit(@ref)

    if tree.entries.empty?
      if @repository.blob_at(@commit.id, @path)
        redirect_to(
          namespace_project_blob_path(@project.namespace, @project,
                                      File.join(@ref, @path))
        ) and return
      elsif @path.present?
        return render_404
      end
    end

    respond_to do |format|
      format.html
      # Disable cache so browser history works
      format.js { no_cache_headers }
    end
  end

  def create_dir
    return render_404 unless @commit_params.values.all?

    begin
      result = Files::CreateDirService.new(@project, current_user, @commit_params).execute
      message = result[:message]
    rescue => e
      message = e.to_s
    end

    if result && result[:status] == :success
      flash[:notice] = "The directory has been successfully created"
      respond_to do |format|
        format.html { redirect_to namespace_project_blob_path(@project.namespace, @project, File.join(@new_branch, @dir_name)) }
      end
    else
      flash[:alert] = message
      respond_to do |format|
        format.html { redirect_to namespace_project_blob_path(@project.namespace, @project, @new_branch) }
      end
    end
  end

  def assign_dir_vars
    @new_branch = params[:new_branch].present? ? sanitize(strip_tags(params[:new_branch])) : @ref
    @dir_name = File.join(@path, params[:dir_name])
    @commit_params = {
      file_path: @dir_name,
      current_branch: @ref,
      target_branch: @new_branch,
      commit_message: params[:commit_message],
    }
  end
end
