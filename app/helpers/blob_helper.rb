module BlobHelper
  def highlighter(blob_name, blob_content, nowrap: false)
    Gitlab::Highlight.new(blob_name, blob_content, nowrap: nowrap)
  end

  def highlight(blob_name, blob_content, nowrap: false)
    Gitlab::Highlight.highlight(blob_name, blob_content, nowrap: nowrap)
  end

  def no_highlight_files
    %w(credits changelog news copying copyright license authors)
  end

  def edit_blob_link(project = @project, ref = @ref, path = @path, options = {})
    return unless current_user

    blob = project.repository.blob_at(ref, path) rescue nil

    return unless blob && blob_text_viewable?(blob)

    from_mr = options[:from_merge_request_id]
    link_opts = {}
    link_opts[:from_merge_request_id] = from_mr if from_mr

    edit_path = namespace_project_edit_blob_path(project.namespace, project,
                                     tree_join(ref, path),
                                     link_opts)

    if !on_top_of_branch?(project, ref)
      button_tag "Edit", class: "btn btn-default disabled has_tooltip", title: "You can only edit files when you are on a branch", data: { container: 'body' }
    elsif can_edit_blob?(blob, project, ref)
      link_to "Edit", edit_path, class: 'btn'
    elsif can?(current_user, :fork_project, project)
      continue_params = {
        to:     edit_path,
        notice: edit_in_new_fork_notice,
        notice_now: edit_in_new_fork_notice_now
      }
      fork_path = namespace_project_forks_path(project.namespace, project, namespace_key: current_user.namespace.id, continue: continue_params)

      link_to "Edit", fork_path, class: 'btn', method: :post
    end
  end

  def modify_file_link(project = @project, ref = @ref, path = @path, label:, action:, btn_class:, modal_type:)
    return unless current_user

    blob = project.repository.blob_at(ref, path) rescue nil

    return unless blob

    if !on_top_of_branch?(project, ref)
      button_tag label, class: "btn btn-#{btn_class} disabled has_tooltip", title: "You can only #{action} files when you are on a branch", data: { container: 'body' }
    elsif blob.lfs_pointer?
      button_tag label, class: "btn btn-#{btn_class} disabled has_tooltip", title: "It is not possible to #{action} files that are stored in LFS using the web interface", data: { container: 'body' }
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
    blob && blob.text? && !blob.lfs_pointer?
  end

  def blob_size(blob)
    if blob.lfs_pointer?
      blob.lfs_size
    else
      blob.size
    end
  end

  def blob_svg?(blob)
    blob.language && blob.language.name == 'SVG'
  end

  # SVGs can contain malicious JavaScript; only include whitelisted
  # elements and attributes. Note that this whitelist is by no means complete
  # and may omit some elements.
  def sanitize_svg(blob)
    blob.data = Loofah.scrub_fragment(blob.data, :strip).to_xml
    blob
  end
end
