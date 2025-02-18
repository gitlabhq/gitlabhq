# frozen_string_literal: true

module TreeHelper
  include BlobHelper
  include WebIdeButtonHelper

  # Return an image icon depending on the file type and mode
  #
  # type - String type of the tree item; either 'folder' or 'file'
  # mode - File unix mode
  # name - File name
  def tree_icon(type, mode, name)
    sprite_icon(file_type_icon_class(type, mode, name))
  end

  # Simple shortcut to File.join
  def tree_join(...)
    File.join(...)
  end

  def on_top_of_branch?(project = @project, ref = @ref)
    project.repository.branch_exists?(ref)
  end

  def can_edit_tree?(project = nil, ref = nil)
    project ||= @project
    ref ||= @ref

    return false unless on_top_of_branch?(project, ref)

    can_collaborate_with_project?(project, ref: ref)
  end

  def tree_edit_branch(project = @project, ref = @ref)
    return unless can_edit_tree?(project, ref)

    patch_branch_name(ref)
  end

  # Generate a patch branch name that should look like:
  # `username-branchname-patch-epoch`
  # where `epoch` is the last 5 digits of the time since epoch (in
  # milliseconds)
  #
  # Note: this correlates with how the WebIDE formats the branch name
  # and if this implementation changes, so should the `placeholderBranchName`
  # definition in app/assets/javascripts/ide/stores/modules/commit/getters.js
  def patch_branch_name(ref)
    return unless current_user

    username = current_user.username
    epoch = time_in_milliseconds.to_s.last(5)

    "#{username}-#{ref}-patch-#{epoch}"
  end

  def edit_in_new_fork_notice_now
    _("You're not allowed to make changes to this project directly. "\
      "A fork of this project is being created that you can make changes in, so you can submit a merge request.")
  end

  def edit_in_new_fork_notice
    _("You're not allowed to make changes to this project directly. "\
      "A fork of this project has been created that you can make changes in, so you can submit a merge request.")
  end

  def edit_in_new_fork_notice_action(action)
    edit_in_new_fork_notice + (_(" Try to %{action} this file again.") % { action: action })
  end

  def path_breadcrumbs(max_links = 6)
    if @path.present?
      part_path = ""
      parts = @path.split('/')

      yield('..', File.join(*parts.first(parts.count - 2))) if parts.count > max_links

      parts.each do |part|
        part_path = File.join(part_path, part) unless part_path.empty?
        part_path = part if part_path.empty?

        next if parts.count > max_links && parts.last(2).exclude?(part)

        yield(part, part_path)
      end
    end
  end

  def selected_branch
    @branch_name || tree_edit_branch
  end

  def relative_url_root
    Gitlab.config.gitlab.relative_url_root.presence || '/'
  end

  def breadcrumb_data_attributes
    attrs = {
      selected_branch: selected_branch,
      can_push_code: can?(current_user, :push_code, @project).to_s,
      can_push_to_branch: user_access(@project).can_push_to_branch?(@ref).to_s,
      can_collaborate: can_collaborate_with_project?(@project).to_s,
      new_blob_path: project_new_blob_path(@project, @ref),
      upload_path: project_create_blob_path(@project, @ref),
      new_dir_path: project_create_dir_path(@project, @ref),
      new_branch_path: new_project_branch_path(@project),
      new_tag_path: new_project_tag_path(@project),
      can_edit_tree: can_edit_tree?.to_s
    }

    if can?(current_user, :fork_project, @project) && can?(current_user, :create_merge_request_in, @project)
      continue_param = {
        to: project_new_blob_path(@project, @id),
        notice: edit_in_new_fork_notice,
        notice_now: edit_in_new_fork_notice_now
      }

      attrs.merge!(
        fork_new_blob_path: project_forks_path(
          @project,
          namespace_key: current_user.namespace.id,
          continue: continue_param
        ),
        fork_new_directory_path: project_forks_path(
          @project,
          namespace_key: current_user.namespace.id,
          continue: continue_param.merge({
            to: request.fullpath,
            notice: _("%{edit_in_new_fork_notice} Try to create a new directory again.") % {
              edit_in_new_fork_notice: edit_in_new_fork_notice
            }
          })
        ),
        fork_upload_blob_path: project_forks_path(
          @project,
          namespace_key: current_user.namespace.id,
          continue: continue_param.merge({
            to: request.fullpath,
            notice: _("%{edit_in_new_fork_notice} Try to upload a file again.") % {
              edit_in_new_fork_notice: edit_in_new_fork_notice
            }
          })
        )
      )
    end

    attrs
  end

  def compare_path(project, repository, ref)
    return if ref.blank? || repository.root_ref == ref

    project_compare_index_path(project, from: repository.root_ref, to: ref)
  end

  def vue_tree_header_app_data(project, repository, ref, pipeline)
    archive_prefix = ref ? "#{project.path}-#{ref.tr('/', '-')}" : ''

    {
      project_id: project.id,
      ref: ref,
      ref_type: @ref_type.to_s,
      breadcrumbs: breadcrumb_data_attributes,
      project_root_path: project_path(project),
      project_path: project.full_path,
      compare_path: compare_path(project, repository, ref),
      web_ide_button_options: web_ide_button_data({ blob: nil }).merge(fork_modal_options(project, nil)).to_json,
      web_ide_button_default_branch: project.default_branch_or_main,
      ssh_url: ssh_enabled? ? ssh_clone_url_to_repo(project) : '',
      http_url: http_enabled? ? http_clone_url_to_repo(project) : '',
      xcode_url: show_xcode_link?(project) ? xcode_uri_to_repo(project) : '',
      download_links: !project.empty_repo? ? download_links(project, ref, archive_prefix).to_json : '',
      download_artifacts: pipeline &&
        (previous_artifacts(project, ref, pipeline.latest_builds_with_artifacts).to_json || []),
      escaped_ref: ActionDispatch::Journey::Router::Utils.escape_path(ref)
    }
  end

  def vue_file_list_data(project, ref)
    {
      project_path: project.full_path,
      project_short_path: project.path,
      target_branch: selected_branch,
      ref: ref,
      escaped_ref: ActionDispatch::Journey::Router::Utils.escape_path(ref),
      full_name: project.name_with_namespace,
      ref_type: @ref_type
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

  def download_links(project, ref, archive_prefix)
    Gitlab::Workhorse::ARCHIVE_FORMATS.map do |fmt|
      {
        text: fmt,
        path: external_storage_url_or_path(
          project_archive_path(project, id: tree_join(ref, archive_prefix), format: fmt)
        )
      }
    end
  end

  def directory_download_links(project, ref, archive_prefix)
    Gitlab::Workhorse::ARCHIVE_FORMATS.map do |fmt|
      {
        text: fmt,
        path: project_archive_path(project, id: tree_join(ref, archive_prefix), format: fmt)
      }
    end
  end
end

def previous_artifacts(project, ref, builds_with_artifacts)
  builds_with_artifacts.map do |job|
    {
      text: job.name,
      path: latest_succeeded_project_artifacts_path(project, "#{ref}/download", job: job.name)
    }
  end
end

TreeHelper.prepend_mod_with('TreeHelper')
