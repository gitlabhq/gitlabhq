module BlobHelper
  def rouge_formatter(options = {})
    default_options = {
      nowrap: false,
      cssclass: 'code highlight',
      lineanchors: true,
      lineanchorsid: 'LC'
    }

    Rouge::Formatters::HTMLGitlab.new(default_options.merge!(options))
  end

  def highlight(blob_name, blob_content, nowrap: false, continue: false)
    @formatter ||= rouge_formatter(nowrap: nowrap)

    begin
      @lexer ||= Rouge::Lexer.guess(filename: blob_name, source: blob_content).new
      result = @formatter.format(@lexer.lex(blob_content, continue: continue)).html_safe
    rescue
      @lexer = Rouge::Lexers::PlainText
      result = @formatter.format(@lexer.lex(blob_content)).html_safe
    end

    result
  end

  def highlight_line(blob_name, content, continue: false)
    if @previous_blob_name != blob_name
      @parent  = Rouge::Lexer.guess(filename: blob_name, source: content).new rescue Rouge::Lexers::PlainText.new
      @lexer   = Rouge::Lexers::GitlabDiff.new(parent_lexer: @parent)
      @options = Rouge::Lexers::PlainText === @parent ? {} : { continue: continue }
    end

    @previous_blob_name = blob_name
    @formatter ||= rouge_formatter(nowrap: true)

    content.sub!(/\A((?:\+|-)\s*)/, '') # Don't format '+' or '-' indicators.

    "#{$1}#{@formatter.format(@lexer.lex(content, @options))}".html_safe
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

    if !on_top_of_branch?
      button_tag "Edit", class: "btn btn-default disabled has_tooltip", title: "You can only edit files when you are on a branch", data: { container: 'body' }
    elsif can_edit_blob?(blob)
      link_to "Edit", edit_path, class: 'btn btn-small'
    elsif can?(current_user, :fork_project, project)
      continue_params = {
        to:     edit_path,
        notice: edit_in_new_fork_notice,
        notice_now: edit_in_new_fork_notice_now
      }
      fork_path = namespace_project_fork_path(project.namespace, project, namespace_key:  current_user.namespace.id,
                                                                          continue:       continue_params)

      link_to "Edit", fork_path, class: 'btn btn-small', method: :post
    end
  end

  def modify_file_link(project = @project, ref = @ref, path = @path, label:, action:, btn_class:, modal_type:)
    return unless current_user

    blob = project.repository.blob_at(ref, path) rescue nil

    return unless blob

    if !on_top_of_branch?
      button_tag label, class: "btn btn-#{btn_class} disabled has_tooltip", title: "You can only #{action} files when you are on a branch", data: { container: 'body' }
    elsif blob.lfs_pointer?
      button_tag label, class: "btn btn-#{btn_class} disabled has_tooltip", title: "It is not possible to #{action} files that are stored in LFS using the web interface", data: { container: 'body' }
    elsif can_edit_blob?(blob)
      button_tag label, class: "btn btn-#{btn_class}", 'data-target' => "#modal-#{modal_type}-blob", 'data-toggle' => 'modal'
    elsif can?(current_user, :fork_project, project)
      continue_params = {
        to:     request.fullpath,
        notice: edit_in_new_fork_notice + " Try to #{action} this file again.",
        notice_now: edit_in_new_fork_notice_now
      }
      fork_path = namespace_project_fork_path(project.namespace, project, namespace_key:  current_user.namespace.id,
                                                                          continue:       continue_params)

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
end
