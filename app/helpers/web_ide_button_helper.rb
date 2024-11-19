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
end
