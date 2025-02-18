# frozen_string_literal: true

module BlobHelper
  def edit_blob_path(project = @project, ref = @ref, path = @path, options = {})
    project_edit_blob_path(project, tree_join(ref, path), options[:link_opts])
  end

  def ide_edit_path(project = @project, ref = @ref, path = @path)
    project_path =
      if !current_user || can?(current_user, :push_code, project)
        project.full_path
      else
        # We currently always fork to the user's namespace
        # in edit_fork_button_tag
        "#{current_user.namespace.full_path}/#{project.path}"
      end

    segments = [ide_path, 'project', project_path, 'edit', encode_ide_path(ref)]
    segments.concat(['-', encode_ide_path(path)]) if path.present?
    File.join(segments)
  end

  def ide_merge_request_path(merge_request, path = '')
    target_project = merge_request.target_project
    source_project = merge_request.source_project

    if merge_request.merged?
      branch = merge_request.target_branch_exists? ? merge_request.target_branch : target_project.default_branch

      return ide_edit_path(target_project, branch, path)
    end

    params = { target_project: target_project.full_path } if target_project != source_project

    result = File.join(ide_path, 'project', source_project.full_path, 'merge_requests', merge_request.to_param)
    result += "?#{params.to_query}" unless params.nil?
    result
  end

  def ide_fork_and_edit_path(project = @project, ref = @ref, path = @path, with_notice: true)
    fork_path_for_current_user(project, ide_edit_path(project, ref, path), with_notice: with_notice)
  end

  def fork_and_edit_path(project = @project, ref = @ref, path = @path, options = {})
    fork_path_for_current_user(project, edit_blob_path(project, ref, path, options))
  end

  def fork_path_for_current_user(project, path, with_notice: true)
    return unless current_user

    project_forks_path(
      project,
      namespace_key: current_user.namespace&.id,
      continue: edit_blob_fork_params(path, with_notice: with_notice)
    )
  end

  def encode_ide_path(path)
    ERB::Util.url_encode(path).gsub('%2F', '/')
  end

  def edit_blob_button(project = @project, ref = @ref, path = @path, options = {})
    return unless blob = readable_blob(options, path, project, ref)

    common_classes = "js-edit-blob gl-ml-3 #{options[:extra_class]}"

    edit_button_tag(
      blob,
      common_classes,
      _('Edit'),
      edit_blob_path(project, ref, path, options),
      project,
      ref
    )
  end

  # Used for single file Web Editor, Delete and Replace UI actions.
  # can_edit_tree checks if ref is on top of the branch.
  def can_modify_blob?(blob, project = @project, ref = @ref)
    !blob.stored_externally? && can_edit_tree?(project, ref)
  end

  # Used for WebIDE editor where editing is possible even if ref is not on top of the branch.
  def can_modify_blob_with_web_ide?(blob, project = @project)
    !blob.stored_externally? && can_collaborate_with_project?(project)
  end

  def leave_edit_message
    _("Leave edit mode? All unsaved changes will be lost.")
  end

  def editing_preview_title(filename)
    if Gitlab::MarkupHelper.previewable?(filename)
      _('Preview')
    else
      _('Preview changes')
    end
  end

  # Return an image icon depending on the file mode and extension
  #
  # mode - File unix mode
  # mode - File name
  def blob_icon(mode, name)
    sprite_icon(file_type_icon_class('file', mode, name))
  end

  def blob_raw_url(**kwargs)
    if @build && @entry
      raw_project_job_artifacts_url(@project, @build, path: @entry.path, **kwargs)
    elsif @snippet
      gitlab_raw_snippet_url(@snippet)
    elsif @blob
      project_raw_url(@project, @id, **kwargs)
    end
  end

  def blob_raw_path(**kwargs)
    blob_raw_url(**kwargs, only_path: true)
  end

  def parent_dir_raw_path
    "#{blob_raw_path.rpartition('/').first}/"
  end

  # SVGs can contain malicious JavaScript; only include allowlisted
  # elements and attributes. Note that this allowlist is by no means complete
  # and may omit some elements.
  def sanitize_svg_data(data)
    Gitlab::Sanitizers::SVG.clean(data)
  end

  def ref_project
    @ref_project ||= @target_project || @project
  end

  def licenses_for_select(project)
    @licenses_for_select ||= TemplateFinder.all_template_names(project, :licenses)
  end

  def gitignore_names(project)
    @gitignore_names ||= TemplateFinder.all_template_names(project, :gitignores)
  end

  def gitlab_ci_ymls(project)
    @gitlab_ci_ymls ||= TemplateFinder.all_template_names(project, :gitlab_ci_ymls)
  end

  def dockerfile_names(project)
    @dockerfile_names ||= TemplateFinder.all_template_names(project, :dockerfiles)
  end

  def blob_editor_paths(project, method)
    {
      'relative-url-root' => Rails.application.config.relative_url_root,
      'assets-prefix' => Gitlab::Application.config.assets.prefix,
      'blob-filename' => @blob && @blob.path,
      'project-id' => project.id,
      'project-path': project.full_path,
      'is-markdown' => @blob && @blob.path && Gitlab::MarkupHelper.gitlab_markdown?(@blob.path),
      'preview-markdown-path' => preview_markdown_path(project),
      'form-method' => method
    }
  end

  def copy_file_path_button(file_path)
    clipboard_button(text: file_path, gfm: "`#{file_path}`", title: _('Copy file path'))
  end

  def copy_blob_source_button(blob)
    return unless blob.rendered_as_text?(ignore_errors: false)

    content_tag(:span, class: 'btn-group has-tooltip js-copy-blob-source-btn-tooltip') do
      clipboard_button(target: ".blob-content[data-blob-id='#{blob.id}'] > pre", class: "js-copy-blob-source-btn", size: :medium)
    end
  end

  def open_raw_blob_button(blob)
    return if blob.empty?
    return if blob.binary? || blob.stored_externally?

    title = _('Open raw')
    render Pajamas::ButtonComponent.new(href: external_storage_url_or_path(blob_raw_path), target: '_blank', icon: 'doc-code', button_options: { title: title, class: 'has-tooltip', rel: 'noopener noreferrer', data: { container: 'body' } })
  end

  def download_blob_button(blob)
    return if blob.empty?

    title = _('Download')
    render Pajamas::ButtonComponent.new(href: external_storage_url_or_path(blob_raw_path(inline: false)), target: '_blank', icon: 'download', button_options: { download: @path, title: title, class: 'has-tooltip', rel: 'noopener noreferrer', data: { container: 'body' } })
  end

  def blob_render_error_reason(viewer)
    case viewer.render_error
    when :collapsed
      "it is larger than #{number_to_human_size(viewer.collapse_limit)}"
    when :too_large
      "it is larger than #{number_to_human_size(viewer.size_limit)}"
    when :server_side_but_stored_externally
      case viewer.blob.external_storage
      when :lfs
        'it is stored in LFS'
      when :build_artifact
        'it is stored as a job artifact'
      else
        'it is stored externally'
      end
    end
  end

  def blob_render_error_options(viewer)
    error = viewer.render_error
    options = []

    if error == :collapsed
      options << link_to('load it anyway', url_for(safe_params.merge(viewer: viewer.type, expanded: true, format: nil)))
    end

    # If the error is `:server_side_but_stored_externally`, the simple viewer will show the same error,
    # so don't bother switching.
    if viewer.rich? && viewer.blob.rendered_as_text? && error != :server_side_but_stored_externally
      options << link_to('view the source', '#', class: 'js-blob-viewer-switch-btn', data: { viewer: 'simple' })
    end

    options << link_to('download it', blob_raw_path, target: '_blank', rel: 'noopener noreferrer')

    options
  end

  def contribution_options(project)
    options = []

    options << link_to("submit an issue", new_project_issue_path(project)) if can?(current_user, :create_issue, project)

    merge_project = merge_request_source_project_for_project(@project)
    options << link_to("create a merge request", project_new_merge_request_path(project)) if merge_project

    options
  end

  def readable_blob(options, path, project, ref)
    blob = options.fetch(:blob) do
      project.repository.blob_at(ref, path)
    rescue StandardError
      nil
    end

    blob if blob&.readable_text?
  end

  def edit_blob_fork_params(path, with_notice: true)
    {
      to: path,
      notice: (edit_in_new_fork_notice if with_notice),
      notice_now: (edit_in_new_fork_notice_now if with_notice)
    }.compact
  end

  def edit_fork_button_tag(common_classes, project, label, params, action = 'edit')
    fork_path = project_forks_path(project, namespace_key: current_user.namespace.id, continue: params)

    render Pajamas::ButtonComponent.new(variant: :confirm, button_options: { class: "#{common_classes} js-edit-blob-link-fork-toggler", data: { action: action, fork_path: fork_path } }) do
      label
    end
  end

  def edit_disabled_button_tag(button_text, common_classes)
    button = render Pajamas::ButtonComponent.new(disabled: true, variant: :confirm, button_options: { class: common_classes }) do
      button_text
    end

    # Disabled buttons with tooltips should have the tooltip attached
    # to a wrapper element https://bootstrap-vue.org/docs/components/tooltip#disabled-elements
    content_tag(:span, button, class: 'has-tooltip', title: _('You can only edit files when you are on a branch'), data: { container: 'body' })
  end

  def edit_link_tag(link_text, edit_path, common_classes)
    render Pajamas::ButtonComponent.new(variant: :confirm, href: edit_path, button_options: { class: common_classes }) do
      link_text
    end
  end

  def edit_button_tag(blob, common_classes, text, edit_path, project, ref)
    if !on_top_of_branch?(project, ref)
      edit_disabled_button_tag(text, common_classes)
      # This condition only applies to users who are logged in
    elsif !current_user || (current_user && can_modify_blob?(blob, project, ref))
      edit_link_tag(text, edit_path, common_classes)
    elsif can?(current_user, :fork_project, project) && can?(current_user, :create_merge_request_in, project)
      edit_fork_button_tag(common_classes, project, text, edit_blob_fork_params(edit_path))
    end
  end

  def vue_blob_app_data(project, blob, ref)
    {
      blob_path: blob.path,
      project_path: project.full_path,
      resource_id: project.to_global_id,
      user_id: current_user.present? ? current_user.to_global_id : '',
      target_branch: selected_branch,
      original_branch: ref,
      can_download_code: can?(current_user, :download_code, project).to_s
    }
  end

  def vue_blob_header_app_data(project, blob, ref)
    {
      blob_path: blob.path,
      is_binary: blob.binary?,
      breadcrumbs: breadcrumb_data_attributes,
      escaped_ref: ActionDispatch::Journey::Router::Utils.escape_path(ref),
      history_link: project_commits_path(project, ref),
      project_id: project.id,
      project_root_path: project_path(project),
      project_path: project.full_path,
      project_short_path: project.path,
      ref_type: @ref_type.to_s,
      ref: ref
    }
  end

  def edit_blob_app_data(project, id, blob, ref, action)
    is_update = action == 'update'
    is_create = action == 'create'
    update_path = if is_update
                    project_update_blob_path(project, id)
                  elsif is_create
                    project_create_blob_path(project, id)
                  end

    cancel_path = if is_update
                    project_blob_path(project, id)
                  elsif is_create
                    project_tree_path(project, id)
                  end

    {
      action: action.to_s,
      update_path: update_path,
      cancel_path: cancel_path,
      original_branch: ref,
      target_branch: selected_branch,
      can_push_code: can?(current_user, :push_code, project).to_s,
      can_push_to_branch: project.present(current_user: current_user).can_current_user_push_to_branch?(ref).to_s,
      empty_repo: project.empty_repo?.to_s,
      blob_name: is_update ? blob.name : nil,
      branch_allows_collaboration: project.branch_allows_collaboration?(current_user, ref).to_s,
      last_commit_sha: @last_commit_sha
    }
  end
end

BlobHelper.prepend_mod_with('BlobHelper')
