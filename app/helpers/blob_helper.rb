# frozen_string_literal: true

module BlobHelper
  def edit_blob_path(project = @project, ref = @ref, path = @path, options = {})
    project_edit_blob_path(project,
                           tree_join(ref, path),
                           options[:link_opts])
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

    if target_project != source_project
      params = { target_project: target_project.full_path }
    end

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

    project_forks_path(project,
                      namespace_key: current_user.namespace&.id,
                      continue: edit_blob_fork_params(path, with_notice: with_notice))
  end

  def encode_ide_path(path)
    ERB::Util.url_encode(path).gsub('%2F', '/')
  end

  def edit_blob_button(project = @project, ref = @ref, path = @path, options = {})
    return unless blob = readable_blob(options, path, project, ref)

    common_classes = "btn gl-button btn-confirm js-edit-blob gl-ml-3 #{options[:extra_class]}"
    data = { track_action: 'click_edit', track_label: 'edit' }

    if Feature.enabled?(:web_ide_primary_edit, project.group)
      common_classes += " btn-inverted"
      data[:track_property] = 'secondary'
    end

    edit_button_tag(blob,
                    common_classes,
                    _('Edit'),
                    edit_blob_path(project, ref, path, options),
                    project,
                    ref,
                    data)
  end

  def ide_edit_button(project = @project, ref = @ref, path = @path, blob:)
    return unless blob

    common_classes = 'btn gl-button btn-confirm ide-edit-button gl-ml-3'
    data = { track_action: 'click_edit_ide', track_label: 'web_ide' }

    unless Feature.enabled?(:web_ide_primary_edit, project.group)
      common_classes += " btn-inverted"
      data[:track_property] = 'secondary'
    end

    edit_button_tag(blob,
                    common_classes,
                    _('Web IDE'),
                    ide_edit_path(project, ref, path),
                    project,
                    ref,
                    data)
  end

  def modify_file_button(project = @project, ref = @ref, path = @path, blob:, label:, action:, btn_class:, modal_type:)
    return unless current_user
    return unless blob

    common_classes = "btn gl-button btn-default btn-#{btn_class}"
    base_button = button_tag(label, class: "#{common_classes} disabled", disabled: true)

    if !on_top_of_branch?(project, ref)
      modify_file_button_tooltip(base_button, _("You can only %{action} files when you are on a branch") % { action: action })
    elsif blob.stored_externally?
      modify_file_button_tooltip(base_button, _("It is not possible to %{action} files that are stored in LFS using the web interface") % { action: action })
    elsif can_modify_blob?(blob, project, ref)
      button_tag label, class: "#{common_classes}", 'data-target' => "#modal-#{modal_type}-blob", 'data-toggle' => 'modal'
    elsif can?(current_user, :fork_project, project) && can?(current_user, :create_merge_request_in, project)
      edit_fork_button_tag(common_classes, project, label, edit_modify_file_fork_params(action), action)
    end
  end

  def replace_blob_link(project = @project, ref = @ref, path = @path, blob:)
    modify_file_button(
      project,
      ref,
      path,
      blob: blob,
      label:      _("Replace"),
      action:     "replace",
      btn_class:  "default",
      modal_type: "upload"
    )
  end

  def delete_blob_link(project = @project, ref = @ref, path = @path, blob:)
    modify_file_button(
      project,
      ref,
      path,
      blob: blob,
      label:      _("Delete"),
      action:     "delete",
      btn_class:  "default",
      modal_type: "remove"
    )
  end

  def can_modify_blob?(blob, project = @project, ref = @ref)
    !blob.stored_externally? && can_edit_tree?(project, ref)
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

  # SVGs can contain malicious JavaScript; only include whitelisted
  # elements and attributes. Note that this whitelist is by no means complete
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

  def metrics_dashboard_ymls(project)
    @metrics_dashboard_ymls ||= TemplateFinder.all_template_names(project, :metrics_dashboard_ymls)
  end

  def dockerfile_names(project)
    @dockerfile_names ||= TemplateFinder.all_template_names(project, :dockerfiles)
  end

  def blob_editor_paths(project)
    {
      'relative-url-root' => Rails.application.config.relative_url_root,
      'assets-prefix' => Gitlab::Application.config.assets.prefix,
      'blob-filename' => @blob && @blob.path,
      'project-id' => project.id,
      'is-markdown' => @blob && @blob.path && Gitlab::MarkupHelper.gitlab_markdown?(@blob.path)
    }
  end

  def copy_file_path_button(file_path)
    clipboard_button(text: file_path, gfm: "`#{file_path}`", class: 'gl-button btn btn-default-tertiary btn-icon btn-sm', title: _('Copy file path'))
  end

  def copy_blob_source_button(blob)
    return unless blob.rendered_as_text?(ignore_errors: false)

    content_tag(:span, class: 'btn-group has-tooltip js-copy-blob-source-btn-tooltip') do
      clipboard_button(target: ".blob-content[data-blob-id='#{blob.id}'] > pre", class: "btn gl-button btn-default btn-icon js-copy-blob-source-btn", hide_tooltip: true)
    end
  end

  def open_raw_blob_button(blob)
    return if blob.empty?
    return if blob.binary? || blob.stored_externally?

    title = _('Open raw')
    link_to sprite_icon('doc-code'),
      external_storage_url_or_path(blob_raw_path),
      class: 'btn gl-button btn-default btn-icon has-tooltip',
      target: '_blank',
      rel: 'noopener noreferrer',
      aria: { label: title },
      title: title,
      data: { container: 'body' }
  end

  def download_blob_button(blob)
    return if blob.empty?

    title = _('Download')
    link_to sprite_icon('download'),
      external_storage_url_or_path(blob_raw_path(inline: false)),
      download: @path,
      class: 'btn gl-button btn-default btn-icon has-tooltip',
      target: '_blank',
      rel: 'noopener noreferrer',
      aria: { label: title },
      title: title,
      data: { container: 'body' }
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

    if can?(current_user, :create_issue, project)
      options << link_to("submit an issue", new_project_issue_path(project))
    end

    merge_project = merge_request_source_project_for_project(@project)
    if merge_project
      options << link_to("create a merge request", project_new_merge_request_path(project))
    end

    options
  end

  def readable_blob(options, path, project, ref)
    blob = options.fetch(:blob) do
      project.repository.blob_at(ref, path) rescue nil
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

  def edit_modify_file_fork_params(action)
    {
      to: request.fullpath,
      notice: edit_in_new_fork_notice_action(action),
      notice_now: edit_in_new_fork_notice_now
    }
  end

  def edit_fork_button_tag(common_classes, project, label, params, action = 'edit')
    fork_path = project_forks_path(project, namespace_key: current_user.namespace.id, continue: params)

    button_tag label,
               class: "#{common_classes} js-edit-blob-link-fork-toggler",
               data: { action: action, fork_path: fork_path }
  end

  def edit_disabled_button_tag(button_text, common_classes)
    button = button_tag(button_text, class: "#{common_classes} disabled", disabled: true)

    # Disabled buttons with tooltips should have the tooltip attached
    # to a wrapper element https://bootstrap-vue.org/docs/components/tooltip#disabled-elements
    content_tag(:span, button, class: 'has-tooltip', title: _('You can only edit files when you are on a branch'), data: { container: 'body' })
  end

  def edit_link_tag(link_text, edit_path, common_classes, data)
    link_to link_text, edit_path, class: "#{common_classes}", data: data
  end

  def edit_button_tag(blob, common_classes, text, edit_path, project, ref, data)
    if !on_top_of_branch?(project, ref)
      edit_disabled_button_tag(text, common_classes)
      # This condition only applies to users who are logged in
    elsif !current_user || (current_user && can_modify_blob?(blob, project, ref))
      edit_link_tag(text, edit_path, common_classes, data)
    elsif can?(current_user, :fork_project, project) && can?(current_user, :create_merge_request_in, project)
      edit_fork_button_tag(common_classes, project, text, edit_blob_fork_params(edit_path))
    end
  end

  def show_suggest_pipeline_creation_celebration?
    @blob.path == Gitlab::FileDetector::PATTERNS[:gitlab_ci] &&
      @blob.auxiliary_viewer&.valid?(project: @project, sha: @commit.sha, user: current_user) &&
      @project.uses_default_ci_config? &&
      cookies[suggest_pipeline_commit_cookie_name].present?
  end

  def suggest_pipeline_commit_cookie_name
    "suggest_gitlab_ci_yml_commit_#{@project.id}"
  end

  def human_access
    @project.team.human_max_access(current_user&.id).try(:downcase)
  end

  def editing_ci_config?
    @path.to_s.end_with?(Ci::Pipeline::CONFIG_EXTENSION) ||
      @path.to_s == @project.ci_config_path_or_default
  end

  private

  def modify_file_button_tooltip(button, tooltip_message)
    # Disabled buttons with tooltips should have the tooltip attached
    # to a wrapper element https://bootstrap-vue.org/docs/components/tooltip#disabled-elements
    content_tag(:span, button, class: 'btn-group has-tooltip', title: tooltip_message, data: { container: 'body' })
  end
end
