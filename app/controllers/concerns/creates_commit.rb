# frozen_string_literal: true

module CreatesCommit
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize
  include SafeFormatHelper
  include ActionView::Helpers::SanitizeHelper

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def create_commit(service, success_path:, failure_path:, failure_view: nil, success_notice: nil, target_project: nil)
    target_project ||= @project

    if user_access(target_project).can_push_to_branch?(branch_name_or_ref)
      @project_to_commit_into = target_project
      @different_project = false
      @branch_name ||= @ref
    else
      @project_to_commit_into = current_user.fork_of(target_project)
      @different_project = true
      @branch_name ||= @project_to_commit_into.repository.next_branch('patch')
    end

    @start_branch ||= @ref || @branch_name

    commit_params = @commit_params.merge(
      start_project: @project_to_commit_into,
      start_branch: @start_branch,
      source_project: @project,
      target_project: target_project,
      branch_name: @branch_name
    )

    result = service.new(@project_to_commit_into, current_user, commit_params).execute

    if result[:status] == :success
      success_path = final_success_path(success_path, target_project)

      update_flash_notice(success_notice, success_path)

      respond_to do |format|
        format.html { redirect_to success_path }
        format.json { render json: { message: _("success"), filePath: success_path } }
      end
    else
      flash[:alert] = format_flash_notice(result[:message])
      failure_path = failure_path.call if failure_path.respond_to?(:call)

      respond_to do |format|
        format.html do
          if failure_view
            render failure_view
          else
            redirect_to failure_path
          end
        end
        format.json do
          render json: {
            error: result[:message],
            filePath: failure_path
          }, status: :unprocessable_entity
        end
      end
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def authorize_edit_tree!
    return if can_collaborate_with_project?(project, ref: branch_name_or_ref)

    access_denied!
  end

  def format_flash_notice(message)
    formatted_message = message.gsub("\n", "<br>")
    sanitize(formatted_message, tags: %w[br])
  end

  private

  def update_flash_notice(success_notice, success_path)
    changes_link = ActionController::Base.helpers.link_to _('changes'), success_path, class: 'gl-link'

    default_message = safe_format(_("Your %{changes_link} have been committed successfully."),
      changes_link: changes_link)

    flash[:notice] = success_notice || default_message

    if create_merge_request?
      flash[:notice] =
        if merge_request_exists?
          nil
        else
          mr_message =
            if @different_project # rubocop:disable Gitlab/ModuleWithInstanceVariables
              _("You can now submit a merge request to get this change into the original project.")
            else
              _("You can now submit a merge request to get this change into the original branch.")
            end

          flash[:notice] += " #{mr_message}"
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
        target_project_id: @project_to_commit_into.default_merge_request_target.id,
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
    MergeRequestsFinder.new(current_user, project_id: @project.id)
        .execute
        .opened
        .find_by(
          source_project_id: @project_to_commit_into,
          source_branch: @branch_name,
          target_branch: @start_branch)
  end
  strong_memoize_attr :merge_request_exists?
  # rubocop: enable CodeReuse/ActiveRecord
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def create_merge_request?
    # Even if the field is set, if we're checking the same branch
    # as the target branch in the same project,
    # we don't want to create a merge request.
    # FIXME: We should use either 1 or true, not both.
    ActiveModel::Type::Boolean.new.cast(params[:create_merge_request]) &&
      (@different_project || @start_branch != @branch_name) # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def branch_name_or_ref
    @branch_name || @ref # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end
end
