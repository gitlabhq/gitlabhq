# frozen_string_literal: true

module WebIdeButtonHelper
  def project_fork
    current_user&.fork_of(@project)
  end

  def project_to_use
    fork? ? project_fork : @project
  end

  def can_collaborate?
    can_collaborate_with_project?(@project)
  end

  def can_create_mr_from_fork?
    can?(current_user, :fork_project, @project) && can?(current_user, :create_merge_request_in, @project)
  end

  def show_web_ide_button?
    can_collaborate? || can_create_mr_from_fork?
  end

  def show_edit_button?(options = {})
    readable_blob?(options) && show_web_ide_button?
  end

  def show_gitpod_button?
    show_web_ide_button? && Gitlab::CurrentSettings.gitpod_enabled
  end

  def show_pipeline_editor_button?(project, path)
    can_view_pipeline_editor?(project) && path == project.ci_config_path_or_default
  end

  def fork?
    !project_fork.nil? && !can_push_code?
  end

  def readable_blob?(options = {})
    !readable_blob(options, @path, @project, @ref).nil?
  end

  def needs_to_fork?
    !can_collaborate? && !current_user&.already_forked?(@project)
  end

  def web_ide_url
    ide_edit_path(project_to_use, @ref, @path || '')
  end

  def edit_url(options = {})
    readable_blob?(options) ? edit_blob_path(@project, @ref, @path || '') : ''
  end

  def gitpod_url
    return "" unless Gitlab::CurrentSettings.gitpod_enabled && @ref

    "#{Gitlab::CurrentSettings.gitpod_url}##{project_tree_url(@project, tree_join(@ref, @path || ''))}"
  end

  def web_ide_button_data(options = {})
    {
      project_path: project_to_use.full_path,
      ref: @ref,

      is_fork: fork?,
      needs_to_fork: needs_to_fork?,
      gitpod_enabled: !current_user.nil? && current_user.gitpod_enabled,
      is_blob: !options[:blob].nil?,

      show_edit_button: show_edit_button?(options),
      show_web_ide_button: show_web_ide_button?,
      show_gitpod_button: show_gitpod_button?,
      show_pipeline_editor_button: show_pipeline_editor_button?(@project, @path),

      web_ide_url: web_ide_url,
      edit_url: edit_url(options),
      pipeline_editor_url: project_ci_pipeline_editor_path(@project, branch_name: @ref),

      gitpod_url: gitpod_url,
      user_preferences_gitpod_path: profile_preferences_path(anchor: 'user_gitpod_enabled'),
      user_profile_enable_gitpod_path: user_settings_profile_path(user: { gitpod_enabled: true })
    }
  end

  def fork_modal_options(project, blob)
    if show_edit_button?({ blob: blob })
      fork_modal_id = "modal-confirm-fork-edit"
    elsif show_web_ide_button?
      fork_modal_id = "modal-confirm-fork-webide"
    end

    {
      fork_path: new_namespace_project_fork_path(project_id: project.path, namespace_id: project.namespace.full_path),
      fork_modal_id: fork_modal_id
    }
  end
end
