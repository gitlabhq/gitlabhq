# frozen_string_literal: true

module BlobHelper
  def highlight(file_name, file_content, language: nil, plain: false)
    highlighted = Gitlab::Highlight.highlight(file_name, file_content, plain: plain, language: language)

    raw %(<pre class="code highlight"><code>#{highlighted}</code></pre>)
  end

  def no_highlight_files
    %w(credits changelog news copying copyright license authors)
  end

  def edit_blob_path(project = @project, ref = @ref, path = @path, options = {})
    project_edit_blob_path(project,
                           tree_join(ref, path),
                           options[:link_opts])
  end

  def ide_edit_path(project = @project, ref = @ref, path = @path, options = {})
    project_path =
      if !current_user || can?(current_user, :push_code, project)
        project.full_path
      else
        # We currently always fork to the user's namespace
        # in edit_fork_button_tag
        "#{current_user.namespace.full_path}/#{project.path}"
      end

    segments = [ide_path, 'project', project_path, 'edit', ref]
    segments.concat(['-', encode_ide_path(path)]) if path.present?
    File.join(segments)
  end

  def ide_fork_and_edit_path(project = @project, ref = @ref, path = @path, options = {})
    if current_user
      project_forks_path(project,
                        namespace_key: current_user&.namespace&.id,
                        continue: edit_blob_fork_params(ide_edit_path(project, ref, path)))
    end
  end

  def encode_ide_path(path)
    url_encode(path).gsub('%2F', '/')
  end

  def edit_blob_button(project = @project, ref = @ref, path = @path, options = {})
    return unless blob = readable_blob(options, path, project, ref)

    common_classes = "btn btn-primary js-edit-blob #{options[:extra_class]}"

    edit_button_tag(blob,
                    common_classes,
                    _('Edit'),
                    Feature.enabled?(:web_ide_default) ? ide_edit_path(project, ref, path, options) : edit_blob_path(project, ref, path, options),
                    project,
                    ref)
  end

  def ide_edit_button(project = @project, ref = @ref, path = @path, options = {})
    return if Feature.enabled?(:web_ide_default)
    return unless blob = readable_blob(options, path, project, ref)

    edit_button_tag(blob,
                    'btn btn-inverted btn-primary ide-edit-button',
                    _('Web IDE'),
                    ide_edit_path(project, ref, path, options),
                    project,
                    ref)
  end

  def modify_file_button(project = @project, ref = @ref, path = @path, label:, action:, btn_class:, modal_type:)
    return unless current_user

    blob = project.repository.blob_at(ref, path) rescue nil

    return unless blob

    common_classes = "btn btn-#{btn_class}"

    if !on_top_of_branch?(project, ref)
      button_tag label, class: "#{common_classes} disabled has-tooltip", title: "You can only #{action} files when you are on a branch", data: { container: 'body' }
    elsif blob.stored_externally?
      button_tag label, class: "#{common_classes} disabled has-tooltip", title: "It is not possible to #{action} files that are stored in LFS using the web interface", data: { container: 'body' }
    elsif can_modify_blob?(blob, project, ref)
      button_tag label, class: "#{common_classes}", 'data-target' => "#modal-#{modal_type}-blob", 'data-toggle' => 'modal'
    elsif can?(current_user, :fork_project, project) && can?(current_user, :create_merge_request_in, project)
      edit_fork_button_tag(common_classes, project, label, edit_modify_file_fork_params(action), action)
    end
  end

  def replace_blob_link(project = @project, ref = @ref, path = @path)
    modify_file_button(
      project,
      ref,
      path,
      label:      _("Replace"),
      action:     "replace",
      btn_class:  "default",
      modal_type: "upload"
    )
  end

  def delete_blob_link(project = @project, ref = @ref, path = @path)
    modify_file_button(
      project,
      ref,
      path,
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
    icon("#{file_type_icon_class('file', mode, name)} fw")
  end

  def blob_raw_url(**kwargs)
    if @build && @entry
      raw_project_job_artifacts_url(@project, @build, path: @entry.path, **kwargs)
    elsif @snippet
      raw_snippet_url(@snippet)
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

  def template_dropdown_names(items)
    grouped = items.group_by(&:category)
    categories = grouped.keys

    categories.each_with_object({}) do |category, hash|
      hash[category] = grouped[category].map do |item|
        { name: item.name, id: item.key }
      end
    end
  end
  private :template_dropdown_names

  def licenses_for_select(project)
    @licenses_for_select ||= template_dropdown_names(TemplateFinder.build(:licenses, project).execute)
  end

  def gitignore_names(project)
    @gitignore_names ||= template_dropdown_names(TemplateFinder.build(:gitignores, project).execute)
  end

  def gitlab_ci_ymls(project)
    @gitlab_ci_ymls ||= template_dropdown_names(TemplateFinder.build(:gitlab_ci_ymls, project).execute)
  end

  def dockerfile_names(project)
    @dockerfile_names ||= template_dropdown_names(TemplateFinder.build(:dockerfiles, project).execute)
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
    clipboard_button(text: file_path, gfm: "`#{file_path}`", class: 'btn-clipboard btn-transparent', title: _('Copy file path'))
  end

  def copy_blob_source_button(blob)
    return unless blob.rendered_as_text?(ignore_errors: false)

    clipboard_button(target: ".blob-content[data-blob-id='#{blob.id}']", class: "btn btn-sm js-copy-blob-source-btn", title: _("Copy file contents"))
  end

  def open_raw_blob_button(blob)
    return if blob.empty?
    return if blob.binary? || blob.stored_externally?

    title = _('Open raw')
    link_to icon('file-code-o'), blob_raw_path, class: 'btn btn-sm has-tooltip', target: '_blank', rel: 'noopener noreferrer', title: title, data: { container: 'body' }
  end

  def download_blob_button(blob)
    return if blob.empty?

    title = _('Download')
    link_to sprite_icon('download'), blob_raw_path(inline: false), download: @path, class: 'btn btn-sm has-tooltip', target: '_blank', rel: 'noopener noreferrer', title: title, data: { container: 'body' }
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
    blob = options.delete(:blob)
    blob ||= project.repository.blob_at(ref, path) rescue nil

    blob if blob&.readable_text?
  end

  def edit_blob_fork_params(path)
    {
      to: path,
      notice: edit_in_new_fork_notice,
      notice_now: edit_in_new_fork_notice_now
    }
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
    button_tag(button_text, class: "#{common_classes} disabled has-tooltip", title: _('You can only edit files when you are on a branch'), data: { container: 'body' })
  end

  def edit_link_tag(link_text, edit_path, common_classes)
    link_to link_text, edit_path, class: "#{common_classes} btn-sm"
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
end
