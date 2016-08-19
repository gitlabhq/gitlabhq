module BlobHelper
  def highlight(blob_name, blob_content, repository: nil, plain: false)
    highlighted = Gitlab::Highlight.highlight(blob_name, blob_content, plain: plain, repository: repository)
    raw %(<pre class="code highlight"><code>#{highlighted}</code></pre>)
  end

  def no_highlight_files
    %w(credits changelog news copying copyright license authors)
  end

  def edit_blob_link(project = @project, ref = @ref, path = @path, options = {})
    return unless current_user

    blob = options.delete(:blob)
    blob ||= project.repository.blob_at(ref, path) rescue nil

    return unless blob

    edit_path = namespace_project_edit_blob_path(project.namespace, project,
                                     tree_join(ref, path),
                                     options[:link_opts])

    if !on_top_of_branch?(project, ref)
      button_tag "Edit", class: "btn disabled has-tooltip btn-file-option", title: "You can only edit files when you are on a branch", data: { container: 'body' }
    elsif can_edit_blob?(blob, project, ref)
      link_to "Edit", edit_path, class: 'btn btn-sm'
    elsif can?(current_user, :fork_project, project)
      continue_params = {
        to:     edit_path,
        notice: edit_in_new_fork_notice,
        notice_now: edit_in_new_fork_notice_now
      }
      fork_path = namespace_project_forks_path(project.namespace, project, namespace_key: current_user.namespace.id, continue: continue_params)

      link_to "Edit", fork_path, class: 'btn btn-file-option', method: :post
    end
  end

  def modify_file_link(project = @project, ref = @ref, path = @path, label:, action:, btn_class:, modal_type:)
    return unless current_user

    blob = project.repository.blob_at(ref, path) rescue nil

    return unless blob

    if !on_top_of_branch?(project, ref)
      button_tag label, class: "btn btn-#{btn_class} disabled has-tooltip", title: "You can only #{action} files when you are on a branch", data: { container: 'body' }
    elsif blob.lfs_pointer?
      button_tag label, class: "btn btn-#{btn_class} disabled has-tooltip", title: "It is not possible to #{action} files that are stored in LFS using the web interface", data: { container: 'body' }
    elsif can_edit_blob?(blob, project, ref)
      button_tag label, class: "btn btn-#{btn_class}", 'data-target' => "#modal-#{modal_type}-blob", 'data-toggle' => 'modal'
    elsif can?(current_user, :fork_project, project)
      continue_params = {
        to:     request.fullpath,
        notice: edit_in_new_fork_notice + " Try to #{action} this file again.",
        notice_now: edit_in_new_fork_notice_now
      }
      fork_path = namespace_project_forks_path(project.namespace, project, namespace_key: current_user.namespace.id, continue: continue_params)

      link_to label, fork_path, class: "btn btn-#{btn_class}", method: :post
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

  def can_edit_blob?(blob, project = @project, ref = @ref)
    !blob.lfs_pointer? && can_edit_tree?(project, ref)
  end

  def leave_edit_message
    "Leave edit mode?\nAll unsaved changes will be lost."
  end

  def editing_preview_title(filename)
    if Gitlab::MarkupHelper.previewable?(filename)
      'Preview'
    else
      'Preview Changes'
    end
  end

  # Return an image icon depending on the file mode and extension
  #
  # mode - File unix mode
  # mode - File name
  def blob_icon(mode, name)
    icon("#{file_type_icon_class('file', mode, name)} fw")
  end

  def blob_text_viewable?(blob)
    blob && blob.text? && !blob.lfs_pointer? && !blob.only_display_raw?
  end

  def blob_size(blob)
    if blob.lfs_pointer?
      blob.lfs_size
    else
      blob.size
    end
  end

  # SVGs can contain malicious JavaScript; only include whitelisted
  # elements and attributes. Note that this whitelist is by no means complete
  # and may omit some elements.
  def sanitize_svg(blob)
    blob.data = Gitlab::Sanitizers::SVG.clean(blob.data)
    blob
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

    if @ref && @commit && @ref == @commit.id
      # This is a link to a commit by its commit SHA. That means that the blob
      # is immutable. The only reason to invalidate the cache is if the commit
      # was deleted or if the user lost access to the repository.
      response.cache_control[:max_age] = Blob::CACHE_TIME_IMMUTABLE
    else
      # A branch or tag points at this blob. That means that the expected blob
      # value may change over time.
      response.cache_control[:max_age] = Blob::CACHE_TIME
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

  def selected_template(issuable)
    templates = issuable_templates(issuable)
    params[:issuable_template] if templates.include?(params[:issuable_template])
  end

  def can_add_template?(issuable)
    names = issuable_templates(issuable)
    names.empty? && can?(current_user, :push_code, @project) && !@project.private?
  end

  def merge_request_template_names
    @merge_request_templates ||= Gitlab::Template::MergeRequestTemplate.dropdown_names(ref_project)
  end

  def issue_template_names
    @issue_templates ||= Gitlab::Template::IssueTemplate.dropdown_names(ref_project)
  end

  def issuable_templates(issuable)
    @issuable_templates ||=
      if issuable.is_a?(Issue)
        issue_template_names
      elsif issuable.is_a?(MergeRequest)
        merge_request_template_names
      end
  end

  def ref_project
    @ref_project ||= @target_project || @project
  end

  def gitignore_names
    @gitignore_names ||= Gitlab::Template::GitignoreTemplate.dropdown_names
  end

  def gitlab_ci_ymls
    @gitlab_ci_ymls ||= Gitlab::Template::GitlabCiYmlTemplate.dropdown_names
  end

  def blob_editor_paths
    {
      'relative-url-root' => Rails.application.config.relative_url_root,
      'assets-prefix' => Gitlab::Application.config.assets.prefix,
      'blob-language' => @blob && @blob.language.try(:ace_mode)
    }
  end
end
