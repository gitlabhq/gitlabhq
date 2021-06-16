# frozen_string_literal: true

module CreatesCommit
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def create_commit(service, success_path:, failure_path:, failure_view: nil, success_notice: nil, target_project: nil)
    target_project ||= @project

    if user_access(target_project).can_push_to_branch?(branch_name_or_ref)
      @project_to_commit_into = target_project
      @branch_name ||= @ref
    else
      @project_to_commit_into = current_user.fork_of(target_project)
      @branch_name ||= @project_to_commit_into.repository.next_branch('patch')
    end

    @start_branch ||= @ref || @branch_name

    start_project = @project_to_commit_into

    commit_params = @commit_params.merge(
      start_project: start_project,
      start_branch: @start_branch,
      branch_name: @branch_name
    )

    result = service.new(@project_to_commit_into, current_user, commit_params).execute

    if result[:status] == :success
      update_flash_notice(success_notice)

      success_path = final_success_path(success_path, target_project)

      respond_to do |format|
        format.html { redirect_to success_path }
        format.json { render json: { message: _("success"), filePath: success_path } }
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
        format.json { render json: { message: _("failed"), filePath: failure_path } }
      end
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def authorize_edit_tree!
    return if can_collaborate_with_project?(project, ref: branch_name_or_ref)

    access_denied!
  end

  private

  def update_flash_notice(success_notice)
    flash[:notice] = success_notice || _("Your changes have been successfully committed.")

    if create_merge_request?
      flash[:notice] =
        if merge_request_exists?
          nil
        else
          mr_message =
            if different_project?
              _("You can now submit a merge request to get this change into the original project.")
            else
              _("You can now submit a merge request to get this change into the original branch.")
            end

          flash[:notice] += " " + mr_message
        end
    end
  end

  def final_success_path(success_path, target_project)
    if create_merge_request?
      merge_request_exists? ? existing_merge_request_path : new_merge_request_path(target_project)
    else
      success_path = success_path.call if success_path.respond_to?(:call)

      success_path
    end
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def new_merge_request_path(target_project)
    project_new_merge_request_path(
      @project_to_commit_into,
      merge_request: {
        source_project_id: @project_to_commit_into.id,
        target_project_id: target_project.id,
        source_branch: @branch_name,
        target_branch: @start_branch
      }
    )
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def existing_merge_request_path
    project_merge_request_path(@project, @merge_request) # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  # rubocop: disable CodeReuse/ActiveRecord
  def merge_request_exists?
    strong_memoize(:merge_request) do
      MergeRequestsFinder.new(current_user, project_id: @project.id)
        .execute
        .opened
        .find_by(
          source_project_id: @project_to_commit_into,
          source_branch: @branch_name,
          target_branch: @start_branch)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def different_project?
    @project_to_commit_into != @project # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def create_merge_request?
    # Even if the field is set, if we're checking the same branch
    # as the target branch in the same project,
    # we don't want to create a merge request.
    params[:create_merge_request].present? &&
      (different_project? || @start_branch != @branch_name) # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def branch_name_or_ref
    @branch_name || @ref # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end
end
