module DiffHelper
  def mark_inline_diffs(old_line, new_line)
    old_diffs, new_diffs = Gitlab::Diff::InlineDiff.new(old_line, new_line).inline_diffs

    marked_old_line = Gitlab::Diff::InlineDiffMarker.new(old_line).mark(old_diffs)
    marked_new_line = Gitlab::Diff::InlineDiffMarker.new(new_line).mark(new_diffs)

    [marked_old_line, marked_new_line]
  end

  def diff_view
    params[:view] == 'parallel' ? 'parallel' : 'inline'
  end

  def diff_hard_limit_enabled?
    params[:force_show_diff].present?
  end

  def diff_options
    options = { ignore_whitespace_change: params[:w] == '1' }
    if diff_hard_limit_enabled?
      options.merge!(Commit.max_diff_options)
    end
    options
  end

  def safe_diff_files(diffs, diff_refs)
    diffs.decorate! { |diff| Gitlab::Diff::File.new(diff, diff_refs) }
  end

  def generate_line_code(file_path, line)
    Gitlab::Diff::LineCode.generate(file_path, line.new_pos, line.old_pos)
  end

  def unfold_bottom_class(bottom)
    (bottom) ? 'js-unfold-bottom' : ''
  end

  def unfold_class(unfold)
    (unfold) ? 'unfold js-unfold' : ''
  end

  def diff_line_content(line)
    if line.blank?
      " &nbsp;".html_safe
    else
      line
    end
  end

  def line_comments
    @line_comments ||= @line_notes.select(&:active?).sort_by(&:created_at).group_by(&:line_code)
  end

  def organize_comments(type_left, type_right, line_code_left, line_code_right)
    comments_left = comments_right = nil

    unless type_left.nil? && type_right == 'new'
      comments_left = line_comments[line_code_left]
    end

    unless type_left.nil? && type_right.nil?
      comments_right = line_comments[line_code_right]
    end

    [comments_left, comments_right]
  end

  def inline_diff_btn
    diff_btn('Inline', 'inline', diff_view == 'inline')
  end

  def parallel_diff_btn
    diff_btn('Side-by-side', 'parallel', diff_view == 'parallel')
  end

  def submodule_link(blob, ref, repository = @repository)
    tree, commit = submodule_links(blob, ref, repository)
    commit_id = if commit.nil?
                  Commit.truncate_sha(blob.id)
                else
                  link_to Commit.truncate_sha(blob.id), commit
                end

    [
      content_tag(:span, link_to(truncate(blob.name, length: 40), tree)),
      '@',
      content_tag(:span, commit_id, class: 'monospace'),
    ].join(' ').html_safe
  end

  def commit_for_diff(diff)
    if diff.deleted_file
      @base_commit || @commit.parent || @commit
    else
      @commit
    end
  end

  def diff_file_html_data(project, diff_commit, diff_file)
    {
      blob_diff_path: namespace_project_blob_diff_path(project.namespace, project,
                                                       tree_join(diff_commit.id, diff_file.file_path))
    }
  end

  def editable_diff?(diff)
    !diff.deleted_file && @merge_request && @merge_request.source_project
  end

  private

  def diff_btn(title, name, selected)
    params_copy = params.dup
    params_copy[:view] = name

    # Always use HTML to handle case where JSON diff rendered this button
    params_copy.delete(:format)

    link_to url_for(params_copy), id: "#{name}-diff-btn", class: (selected ? 'btn active' : 'btn'), data: { view_type: name } do
      title
    end
  end
end
