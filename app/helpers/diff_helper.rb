module DiffHelper
  def mark_inline_diffs(old_line, new_line)
    old_diffs, new_diffs = Gitlab::Diff::InlineDiff.new(old_line, new_line).inline_diffs

    marked_old_line = Gitlab::Diff::InlineDiffMarker.new(old_line).mark(old_diffs, mode: :deletion)
    marked_new_line = Gitlab::Diff::InlineDiffMarker.new(new_line).mark(new_diffs, mode: :addition)

    [marked_old_line, marked_new_line]
  end

  def expand_all_diffs?
    params[:expand_all_diffs].present?
  end

  def diff_view
    @diff_view ||= begin
      diff_views = %w(inline parallel)
      diff_view = cookies[:diff_view]
      diff_view = diff_views.first unless diff_views.include?(diff_view)
      diff_view.to_sym
    end
  end

  def diff_options
    options = { ignore_whitespace_change: hide_whitespace?, no_collapse: expand_all_diffs? }

    if action_name == 'diff_for_path'
      options[:no_collapse] = true
      options[:paths] = params.values_at(:old_path, :new_path)
    end

    options
  end

  def diff_match_line(old_pos, new_pos, text: '', view: :inline, bottom: false)
    content = content_tag :td, text, class: "line_content match #{view == :inline ? '' : view}"
    cls = ['diff-line-num', 'unfold', 'js-unfold']
    cls << 'js-unfold-bottom' if bottom

    html = ''
    if old_pos
      html << content_tag(:td, '...', class: cls + ['old_line'], data: { linenumber: old_pos })
      html << content unless view == :inline
    end

    if new_pos
      html << content_tag(:td, '...', class: cls + ['new_line'], data: { linenumber: new_pos })
      html << content
    end

    html.html_safe
  end

  def diff_line_content(line, line_type = nil)
    if line.blank?
      " &nbsp;".html_safe
    else
      line[0] = ' ' if %w[new old].include?(line_type)
      line
    end
  end

  def parallel_diff_discussions(left, right, diff_file)
    discussion_left = discussion_right = nil

    if left && (left.unchanged? || left.removed?)
      line_code = diff_file.line_code(left)
      discussion_left = @grouped_diff_discussions[line_code]
    end

    if right && right.added?
      line_code = diff_file.line_code(right)
      discussion_right = @grouped_diff_discussions[line_code]
    end

    [discussion_left, discussion_right]
  end

  def inline_diff_btn
    diff_btn('Inline', 'inline', diff_view == :inline)
  end

  def parallel_diff_btn
    diff_btn('Side-by-side', 'parallel', diff_view == :parallel)
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

  def commit_for_diff(diff_file)
    return diff_file.content_commit if diff_file.content_commit

    if diff_file.deleted_file
      @base_commit || @commit.parent || @commit
    else
      @commit
    end
  end

  def diff_file_html_data(project, diff_file_path, diff_commit_id)
    {
      blob_diff_path: namespace_project_blob_diff_path(project.namespace, project,
                                                       tree_join(diff_commit_id, diff_file_path)),
      view: diff_view
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

  def commit_diff_whitespace_link(project, commit, options)
    url = namespace_project_commit_path(project.namespace, project, commit.id, params_with_whitespace)
    toggle_whitespace_link(url, options)
  end

  def diff_merge_request_whitespace_link(project, merge_request, options)
    url = diffs_namespace_project_merge_request_path(project.namespace, project, merge_request, params_with_whitespace)
    toggle_whitespace_link(url, options)
  end

  def diff_compare_whitespace_link(project, from, to, options)
    url = namespace_project_compare_path(project.namespace, project, from, to, params_with_whitespace)
    toggle_whitespace_link(url, options)
  end

  def hide_whitespace?
    params[:w] == '1'
  end

  def params_with_whitespace
    hide_whitespace? ? request.query_parameters.except(:w) : request.query_parameters.merge(w: 1)
  end

  def toggle_whitespace_link(url, options)
    options[:class] ||= ''
    options[:class] << ' btn btn-default'

    link_to "#{hide_whitespace? ? 'Show' : 'Hide'} whitespace changes", url, class: options[:class]
  end
end
