module BlobHelper
  def highlight(blob_name, blob_content, nowrap: false, continue: false)
    @formatter ||= Rouge::Formatters::HTMLGitlab.new(
      nowrap: nowrap,
      cssclass: 'code highlight',
      lineanchors: true,
      lineanchorsid: 'LC'
    )

    begin
      @lexer ||= Rouge::Lexer.guess(filename: blob_name, source: blob_content).new
      result = @formatter.format(@lexer.lex(blob_content, continue: continue)).html_safe
    rescue
      @lexer = Rouge::Lexers::PlainText
      result = @formatter.format(@lexer.lex(blob_content)).html_safe
    end

    result
  end

  def no_highlight_files
    %w(credits changelog news copying copyright license authors)
  end

  def edit_blob_link(project, ref, path, options = {})
    blob =
      begin
        project.repository.blob_at(ref, path)
      rescue
        nil
      end

    return unless blob && blob.text? && blob_editable?(blob)

    text = 'Edit'
    after = options[:after] || ''
    from_mr = options[:from_merge_request_id]
    link_opts = {}
    link_opts[:from_merge_request_id] = from_mr if from_mr
    cls = 'btn btn-small'
    link_to(text,
            namespace_project_edit_blob_path(project.namespace, project,
                                             tree_join(ref, path),
                                             link_opts),
            class: cls
           ) + after.html_safe
  end

  def blob_editable?(blob, project = @project, ref = @ref)
    !blob.lfs_pointer? && allowed_tree_edit?(project, ref)
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

  def blob_viewable?(blob)
    blob && blob.text? && !blob.lfs_pointer?
  end

  def blob_size(blob)
    if blob.lfs_pointer?
      blob.lfs_size
    else
      blob.size
    end
  end
end
