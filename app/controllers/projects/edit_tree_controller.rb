class Projects::EditTreeController < Projects::BaseTreeController
  before_filter :authorize_show_blob_edit!, only: [:show]
  before_filter :authorize_push!, only: [:preview, :update]
  before_filter :require_branch_head

  before_filter :blob
  before_filter :from_merge_request
  before_filter :after_edit_path

  def show
    set_show_vars
    params[:content] = @blob.data
    params[:on_my_fork] = true if params[:on_my_fork].nil?
    params[:new_branch_name] = gon.new_branch_name_this
  end

  def update
    set_show_vars
    source_project = @project
    target_project = @project
    source_branch_name = @ref
    if params[:create_merge_request]
      source_branch_name = params[:new_branch_name]
      if params[:on_my_fork]
        if current_user.already_forked?(target_project)
          source_project = current_user.fork_of(target_project)
        else
          source_project = Projects::ForkService.
            new(target_project, current_user).execute
          if source_project.errors.any?
            flash[:alert] = source_project.errors.full_messages.first
            render :show and return
          end
        end
      else
        # No need for error message: Javascript logic makes this impossible.
        authorize_push!
      end
      result = CreateBranchService.new(source_project, current_user).
        execute(source_branch_name, @ref)
      if result[:status] == :error
        flash[:alert] = result[:message]
        render :show and return
      end
    end
    result = Files::UpdateService.new(source_project, current_user, params,
                                      source_branch_name, @path).execute
    if result[:status] == :success
      flash[:notice] = 'Your changes have been successfully committed'
      if params[:create_merge_request]
        redirect_to new_project_merge_request_path(
          source_project,
          merge_request: {
            source_branch:     source_branch_name,
            target_project_id: target_project.id
          }
        )
      else
        if from_merge_request
          from_merge_request.reload_code
        end
        redirect_to after_edit_path
      end
    else
      flash[:alert] = result[:message]
      render :show
    end
  end

  def preview
    @content = params[:content]

    diffy = Diffy::Diff.new(@blob.data, @content, diff: '-U 3',
                            include_diff_info: true)
    @diff_lines = Gitlab::Diff::Parser.new.parse(diffy.diff.scan(/.*\n/))

    render layout: false
  end

  private

  def blob
    @blob ||= @repository.blob_at(@commit.id, @path)
  end

  def after_edit_path
    @after_edit_path ||=
      if from_merge_request
        diffs_project_merge_request_path(from_merge_request.target_project, from_merge_request) +
          "#file-path-#{hexdigest(@path)}"
      else
        project_blob_path(@project, @id)
      end
  end

  def from_merge_request
    # If blob edit was initiated from merge request page
    @from_merge_request ||= MergeRequest.find_by(id: params[:from_merge_request_id])
  end

  def set_show_vars
    @last_commit = Gitlab::Git::Commit.last_for_path(@repository, @ref, @path).sha

    prefix = 'patch-'
    gon.new_branch_name_this = @repository.free_branch_name(prefix)
    if current_user.already_forked?(@project)
      gon.new_branch_name_fork = current_user.fork_of(@project).
        repository.free_branch_name(prefix)
    else
      gon.new_branch_name_fork = gon.new_branch_name_this
    end
  end

  def authorize_show_blob_edit!
    return access_denied! unless can_show_blob_edit?
  end
end
