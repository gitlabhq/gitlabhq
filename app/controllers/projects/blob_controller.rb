# Controller for viewing a file's blame
class Projects::BlobController < Projects::ApplicationController
  include ExtractsPath
  include ActionView::Helpers::SanitizeHelper

  # Raised when given an invalid file path
  class InvalidPathError < StandardError; end

  before_filter :require_non_empty_project, except: [:new, :create]
  before_filter :authorize_download_code!
  before_filter :authorize_push_code!, only: [:destroy]
  before_filter :assign_blob_vars
  before_filter :commit, except: [:new, :create]
  before_filter :blob, except: [:new, :create]
  before_filter :from_merge_request, only: [:edit, :update]
  before_filter :after_edit_path, only: [:edit, :update]
  before_filter :require_branch_head, only: [:edit, :update]

  def new
    commit unless @repository.empty?
  end

  def create
    file_path = File.join(@path, File.basename(params[:file_name]))
    result = Files::CreateService.new(
      @project,
      current_user,
      params.merge(new_branch: sanitized_new_branch_name),
      @ref,
      file_path
    ).execute

    if result[:status] == :success
      flash[:notice] = "Your changes have been successfully committed"
      ref = sanitized_new_branch_name.presence || @ref
      redirect_to namespace_project_blob_path(@project.namespace, @project, File.join(ref, file_path))
    else
      flash[:alert] = result[:message]
      render :new
    end
  end

  def show
  end

  def edit
    @last_commit = Gitlab::Git::Commit.last_for_path(@repository, @ref, @path).sha
  end

  def update
    result = Files::UpdateService.
      new(
        @project,
        current_user,
        params.merge(new_branch: sanitized_new_branch_name),
        @ref,
        @path
      ).execute

    if result[:status] == :success
      flash[:notice] = "Your changes have been successfully committed"

      if from_merge_request
        from_merge_request.reload_code
      end

      redirect_to after_edit_path
    else
      flash[:alert] = result[:message]
      render :edit
    end
  end

  def preview
    @content = params[:content]
    diffy = Diffy::Diff.new(@blob.data, @content, diff: '-U 3', include_diff_info: true)
    @diff_lines = Gitlab::Diff::Parser.new.parse(diffy.diff.scan(/.*\n/))

    render layout: false
  end

  def destroy
    result = Files::DeleteService.new(@project, current_user, params, @ref, @path).execute

    if result[:status] == :success
      flash[:notice] = "Your changes have been successfully committed"
      redirect_to namespace_project_tree_path(@project.namespace, @project,
                                              @ref)
    else
      flash[:alert] = result[:message]
      render :show
    end
  end

  def diff
    @form = UnfoldForm.new(params)
    @lines = @blob.data.lines[@form.since - 1..@form.to - 1]

    if @form.bottom?
      @match_line = ''
    else
      lines_length = @lines.length - 1
      line = [@form.since, lines_length].join(',')
      @match_line = "@@ -#{line}+#{line} @@"
    end

    render layout: false
  end

  private

  def blob
    @blob ||= @repository.blob_at(@commit.id, @path)

    if @blob
      @blob
    else
      if tree = @repository.tree(@commit.id, @path)
        if tree.entries.any?
          redirect_to namespace_project_tree_path(@project.namespace, @project, File.join(@ref, @path)) and return
        end
      end

      return not_found!
    end
  end

  def commit
    @commit = @repository.commit(@ref)

    return not_found! unless @commit
  end

  def assign_blob_vars
    @id = params[:id]
    @ref, @path = extract_ref(@id)


  rescue InvalidPathError
    not_found!
  end

  def after_edit_path
    @after_edit_path ||=
      if from_merge_request
        diffs_namespace_project_merge_request_path(from_merge_request.target_project.namespace, from_merge_request.target_project, from_merge_request) +
          "#file-path-#{hexdigest(@path)}"
      elsif sanitized_new_branch_name.present?
        namespace_project_blob_path(@project.namespace, @project, File.join(sanitized_new_branch_name, @path))
      else
        namespace_project_blob_path(@project.namespace, @project, @id)
      end
  end

  def from_merge_request
    # If blob edit was initiated from merge request page
    @from_merge_request ||= MergeRequest.find_by(id: params[:from_merge_request_id])
  end

  def sanitized_new_branch_name
    @new_branch ||= sanitize(strip_tags(params[:new_branch]))
  end
end
