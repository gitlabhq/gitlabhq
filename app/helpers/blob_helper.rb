module BlobHelper
  def highlight(blob_name, blob_content, nowrap = false)
    formatter = Rugments::Formatters::HTML.new(
      nowrap: nowrap,
      cssclass: 'code highlight',
      lineanchors: true,
      lineanchorsid: 'LC'
    )

    begin
      lexer = Rugments::Lexer.guess(filename: blob_name, source: blob_content)
    rescue Rugments::Lexer::AmbiguousGuess
      lexer = Rugments::Lexers::PlainText
    end

    formatter.format(lexer.lex(blob_content)).html_safe
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

    if blob && blob.text?
      text = 'Edit'
      after = options[:after] || ''
      from_mr = options[:from_merge_request_id]
      link_opts = {}
      link_opts[:from_merge_request_id] = from_mr if from_mr
      cls = 'btn btn-small'
      if allowed_tree_edit?(project, ref)
        link_to(text,
                namespace_project_edit_blob_path(project.namespace, project,
                                                 tree_join(ref, path),
                                                 link_opts),
                class: cls
               )
      else
        content_tag :span, text, class: cls + ' disabled'
      end + after.html_safe
    else
      ''
    end
  end

  def leave_edit_message
    "Leave edit mode?\nAll unsaved changes will be lost."
  end

  def editing_preview_title(filename)
    if Gitlab::MarkdownHelper.previewable?(filename)
      'Preview'
    else
      'Preview changes'
    end
  end
end
