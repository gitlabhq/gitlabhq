module CreatesCommit
  extend ActiveSupport::Concern

  def create_commit(service, success_path:, failure_path:, failure_view: nil, success_notice: nil)
    set_commit_variables

    commit_params = @commit_params.merge(
      start_project: @mr_target_project,
      start_branch: @mr_target_branch,
      target_branch: @mr_source_branch
    )

    result = service.new(
      @mr_source_project, current_user, commit_params).execute

    if result[:status] == :success
      update_flash_notice(success_notice)

      success_path = final_success_path(success_path)

      respond_to do |format|
        format.html { redirect_to success_path }
        format.json { render json: { message: "success", filePath: success_path } }
      end
    else
      flash[:alert] = result[:message]
      failure_path = failure_path.call if failure_path.respond_to?(:call)

      respond_to do |format|
        format.html do
          if failure_view
            render failure_view
          else
            redirect_to failure_path
          end
        end
        format.json { render json: { message: "failed", filePath: failure_path } }
      end
    end
  end

  def authorize_edit_tree!
    return if can_collaborate_with_project?

    access_denied!
  end

  private

  def update_flash_notice(success_notice)
    flash[:notice] = success_notice || "Your changes have been successfully committed."

    if create_merge_request?
      if merge_request_exists?
        flash[:notice] = nil
      else
        target = different_project? ? "project" : "branch"
        flash[:notice] << " You can now submit a merge request to get this change into the original #{target}."
      end
    end
  end

  def final_success_path(success_path)
    if create_merge_request?
      merge_request_exists? ? existing_merge_request_path : new_merge_request_path
    else
      success_path = success_path.call if success_path.respond_to?(:call)

      success_path
    end
  end

  def new_merge_request_path
    new_namespace_project_merge_request_path(
      @mr_source_project.namespace,
      @mr_source_project,
      merge_request: {
        source_project_id: @mr_source_project.id,
        target_project_id: @mr_target_project.id,
        source_branch: @mr_source_branch,
        target_branch: @mr_target_branch
      }
    )
  end

  def existing_merge_request_path
    namespace_project_merge_request_path(@mr_target_project.namespace, @mr_target_project, @merge_request)
  end

  def merge_request_exists?
    return @merge_request if defined?(@merge_request)

    @merge_request = MergeRequestsFinder.new(current_user, project_id: @mr_target_project.id).execute.opened.
      find_by(source_branch: @mr_source_branch, target_branch: @mr_target_branch, source_project_id: @mr_source_project)
  end

  def different_project?
    @mr_source_project != @mr_target_project
  end

  def create_merge_request?
    # Even if the field is set, if we're checking the same branch
    # as the target branch in the same project,
    # we don't want to create a merge request.
    params[:create_merge_request].present? &&
      (different_project? || @mr_target_branch != @mr_source_branch)
  end

  def set_commit_variables
    if can?(current_user, :push_code, @project)
      @mr_source_project = @project
      @target_branch ||= @ref
    else
      @mr_source_project = current_user.fork_of(@project)
      @target_branch ||= @mr_source_project.repository.next_branch('patch')
    end

    # Merge request to this project
    @mr_target_project = @project
    @mr_target_branch ||= @ref || @target_branch

    @mr_source_branch = @target_branch
  end
end
