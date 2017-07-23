module BlobHelper
  def highlight(blob_name, blob_content, repository: nil, plain: false)
    highlighted = Gitlab::Highlight.highlight(blob_name, blob_content, plain: plain, repository: repository)
    raw %(<pre class="code highlight"><code>#{highlighted}</code></pre>)
  end

  def no_highlight_files
    %w(credits changelog news copying copyright license authors)
  end

  def edit_path(project = @project, ref = @ref, path = @path, options = {})
    project_edit_blob_path(project,
                                     tree_join(ref, path),
                                     options[:link_opts])
  end

  def edit_blob_link(project = @project, ref = @ref, path = @path, options = {})
    blob = options.delete(:blob)
    blob ||= project.repository.blob_at(ref, path) rescue nil

    return unless blob && blob.readable_text?

    common_classes = "btn js-edit-blob #{options[:extra_class]}"

    if !on_top_of_branch?(project, ref)
      button_tag 'Edit', class: "#{common_classes} disabled has-tooltip", title: "You can only edit files when you are on a branch", data: { container: 'body' }
    # This condition applies to anonymous or users who can edit directly
    elsif !current_user || (current_user && can_modify_blob?(blob, project, ref))
      link_to 'Edit', edit_path(project, ref, path, options), class: "#{common_classes} btn-sm"
    elsif current_user && can?(current_user, :fork_project, project)
      continue_params = {
        to: edit_path(project, ref, path, options),
        notice: edit_in_new_fork_notice,
        notice_now: edit_in_new_fork_notice_now
      }
      fork_path = project_forks_path(project, namespace_key: current_user.namespace.id, continue: continue_params)

      button_tag 'Edit',
        class: "#{common_classes} js-edit-blob-link-fork-toggler",
        data: { action: 'edit', fork_path: fork_path }
    end
  end

  def modify_file_link(project = @project, ref = @ref, path = @path, label:, action:, btn_class:, modal_type:)
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
    elsif can?(current_user, :fork_project, project)
      continue_params = {
        to: request.fullpath,
        notice: edit_in_new_fork_notice + " Try to #{action} this file again.",
        notice_now: edit_in_new_fork_notice_now
      }
      fork_path = project_forks_path(project, namespace_key: current_user.namespace.id, continue: continue_params)

      button_tag label,
        class: "#{common_classes} js-edit-blob-link-fork-toggler",
        data: { action: action, fork_path: fork_path }
    end
  end

  def replace_blob_link(project = @project, ref = @ref, path = @path)
    modify_file_link(
      project,
      ref,
      path,
      label:      "Replace",
      action:     "replace",
      btn_class:  "default",
      modal_type: "upload"
    )
  end

  def delete_blob_link(project = @project, ref = @ref, path = @path)
    modify_file_link(
      project,
      ref,
      path,
      label:      "Delete",
      action:     "delete",
      btn_class:  "remove",
      modal_type: "remove"
    )
  end

  def can_modify_blob?(blob, project = @project, ref = @ref)
    !blob.stored_externally? && can_edit_tree?(project, ref)
  end

  def leave_edit_message
    "Leave edit mode?\nAll unsaved changes will be lost."
  end

  def editing_preview_title(filename)
    if Gitlab::MarkupHelper.previewable?(filename)
      'Preview'
    else
      'Preview changes'
    end
  end

  # Return an image icon depending on the file mode and extension
  #
  # mode - File unix mode
  # mode - File name
  def blob_icon(mode, name)
    icon("#{file_type_icon_class('file', mode, name)} fw")
  end

  def blob_raw_url
    if @build && @entry
      raw_project_job_artifacts_path(@project, @build, path: @entry.path)
    elsif @snippet
      if @snippet.project_id
        raw_project_snippet_path(@project, @snippet)
      else
        raw_snippet_path(@snippet)
      end
    elsif @blob
      project_raw_path(@project, @id)
    end
  end

  # SVGs can contain malicious JavaScript; only include whitelisted
  # elements and attributes. Note that this whitelist is by no means complete
  # and may omit some elements.
  def sanitize_svg_data(data)
    Gitlab::Sanitizers::SVG.clean(data)
  end

  # If we blindly set the 'real' content type when serving a Git blob we
  # are enabling XSS attacks. An attacker could upload e.g. a Javascript
  # file to a Git repository, trick the browser of a victim into
  # downloading the blob, and then the 'application/javascript' content
  # type would tell the browser to execute the attacker's Javascript. By
  # overriding the content type and setting it to 'text/plain' (in the
  # example of Javascript) we tell the browser of the victim not to
  # execute untrusted data.
  def safe_content_type(blob)
    if blob.text?
      'text/plain; charset=utf-8'
    elsif blob.image?
      blob.content_type
    else
      'application/octet-stream'
    end
  end

  def cached_blob?
    stale = stale?(etag: @blob.id) # The #stale? method sets cache headers.

    # Because we are opionated we set the cache headers ourselves.
    response.cache_control[:public] = @project.public?

    response.cache_control[:max_age] =
      if @ref && @commit && @ref == @commit.id
        # This is a link to a commit by its commit SHA. That means that the blob
        # is immutable. The only reason to invalidate the cache is if the commit
        # was deleted or if the user lost access to the repository.
        Blob::CACHE_TIME_IMMUTABLE
      else
        # A branch or tag points at this blob. That means that the expected blob
        # value may change over time.
        Blob::CACHE_TIME
      end

    response.etag = @blob.id
    !stale
  end

  def licenses_for_select
    return @licenses_for_select if defined?(@licenses_for_select)

    licenses = Licensee::License.all

    @licenses_for_select = {
      Popular: licenses.select(&:featured).map { |license| { name: license.name, id: license.key } },
      Other: licenses.reject(&:featured).map { |license| { name: license.name, id: license.key } }
    }
  end

  def ref_project
    @ref_project ||= @target_project || @project
  end

  def gitignore_names
    @gitignore_names ||= Gitlab::Template::GitignoreTemplate.dropdown_names
  end

  def gitlab_ci_ymls
    @gitlab_ci_ymls ||= Gitlab::Template::GitlabCiYmlTemplate.dropdown_names(params[:context])
  end

  def dockerfile_names
    @dockerfile_names ||= Gitlab::Template::DockerfileTemplate.dropdown_names
  end

  def blob_editor_paths
    {
      'relative-url-root' => Rails.application.config.relative_url_root,
      'assets-prefix' => Gitlab::Application.config.assets.prefix,
      'blob-language' => @blob && @blob.language.try(:ace_mode)
    }
  end

  def copy_file_path_button(file_path)
    clipboard_button(text: file_path, gfm: "`#{file_path}`", class: 'btn-clipboard btn-transparent prepend-left-5', title: 'Copy file path to clipboard')
  end

  def copy_blob_source_button(blob)
    return unless blob.rendered_as_text?(ignore_errors: false)

    clipboard_button(target: ".blob-content[data-blob-id='#{blob.id}']", class: "btn btn-sm js-copy-blob-source-btn", title: "Copy source to clipboard")
  end

  def open_raw_blob_button(blob)
    return if blob.empty?

    if blob.raw_binary? || blob.stored_externally?
      icon = icon('download')
      title = 'Download'
    else
      icon = icon('file-code-o')
      title = 'Open raw'
    end

    link_to icon, blob_raw_url, class: 'btn btn-sm has-tooltip', target: '_blank', rel: 'noopener noreferrer', title: title, data: { container: 'body' }
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
      options << link_to('load it anyway', url_for(params.merge(viewer: viewer.type, expanded: true, format: nil)))
    end

    # If the error is `:server_side_but_stored_externally`, the simple viewer will show the same error,
    # so don't bother switching.
    if viewer.rich? && viewer.blob.rendered_as_text? && error != :server_side_but_stored_externally
      options << link_to('view the source', '#', class: 'js-blob-viewer-switch-btn', data: { viewer: 'simple' })
    end

    options << link_to('download it', blob_raw_url, target: '_blank', rel: 'noopener noreferrer')

    options
  end

  def contribution_options(project)
    options = []

    if can?(current_user, :create_issue, project)
      options << link_to("submit an issue", new_project_issue_path(project))
    end

    merge_project = can?(current_user, :create_merge_request, project) ? project : (current_user && current_user.fork_of(project))
    if merge_project
      options << link_to("create a merge request", project_new_merge_request_path(project))
    end

    options
  end
end
