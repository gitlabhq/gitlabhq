# frozen_string_literal: true

module DiffHelper
  def mark_inline_diffs(old_line, new_line)
    old_diffs, new_diffs = Gitlab::Diff::InlineDiff.new(old_line, new_line).inline_diffs

    marked_old_line = Gitlab::Diff::InlineDiffMarker.new(old_line).mark(old_diffs, mode: :deletion)
    marked_new_line = Gitlab::Diff::InlineDiffMarker.new(new_line).mark(new_diffs, mode: :addition)

    [marked_old_line, marked_new_line]
  end

  def diffs_expanded?
    params[:expanded].present?
  end

  def diff_view
    @diff_view ||= begin
      diff_views = %w(inline parallel)
      diff_view = params[:view] || cookies[:diff_view]
      diff_view = diff_views.first unless diff_views.include?(diff_view)
      diff_view.to_sym
    end
  end

  def diff_options
    options = { ignore_whitespace_change: hide_whitespace?, expanded: diffs_expanded? }

    if action_name == 'diff_for_path'
      options[:expanded] = true
      options[:paths] = params.values_at(:old_path, :new_path)
    end

    options
  end

  def diff_match_line(old_pos, new_pos, text: '', view: :inline, bottom: false)
    content_line_class = %w[line_content match]
    content_line_class << 'parallel' if view == :parallel

    line_num_class = %w[diff-line-num unfold js-unfold]
    line_num_class << 'js-unfold-bottom' if bottom

    html = []

    if old_pos
      html << content_tag(:td, '...', class: [*line_num_class, 'old_line'], data: { linenumber: old_pos })
      html << content_tag(:td, text, class: [*content_line_class, 'left-side']) if view == :parallel
    end

    if new_pos
      html << content_tag(:td, '...', class: [*line_num_class, 'new_line'], data: { linenumber: new_pos })
      html << content_tag(:td, text, class: [*content_line_class, ('right-side' if view == :parallel)])
    end

    html.join.html_safe
  end

  def diff_line_content(line)
    if line.blank?
      "&nbsp;".html_safe
    else
      # `sub` and substring-ing would destroy HTML-safeness of `line`
      if line.start_with?('+', '-', ' ')
        line.dup.tap do |line|
          line[0] = ''
        end
      else
        line
      end
    end
  end

  def parallel_diff_discussions(left, right, diff_file)
    return unless @grouped_diff_discussions

    discussions_left = discussions_right = nil

    if left && left.discussable? && (left.unchanged? || left.removed?)
      line_code = diff_file.line_code(left)
      discussions_left = @grouped_diff_discussions[line_code]
    end

    if right && right.discussable? && right.added?
      line_code = diff_file.line_code(right)
      discussions_right = @grouped_diff_discussions[line_code]
    end

    [discussions_left, discussions_right]
  end

  def inline_diff_btn
    diff_btn('Inline', 'inline', diff_view == :inline)
  end

  def parallel_diff_btn
    diff_btn('Side-by-side', 'parallel', diff_view == :parallel)
  end

  def submodule_link(blob, ref, repository = @repository)
    project_url, tree_url = submodule_links(blob, ref, repository)
    commit_id = if tree_url.nil?
                  Commit.truncate_sha(blob.id)
                else
                  link_to Commit.truncate_sha(blob.id), tree_url
                end

    [
      content_tag(:span, link_to(truncate(blob.name, length: 40), project_url)),
      '@',
      content_tag(:span, commit_id, class: 'commit-sha')
    ].join(' ').html_safe
  end

  def diff_file_blob_raw_url(diff_file, only_path: false)
    project_raw_url(@project, tree_join(diff_file.content_sha, diff_file.file_path), only_path: only_path)
  end

  def diff_file_old_blob_raw_url(diff_file, only_path: false)
    sha = diff_file.old_content_sha
    return unless sha

    project_raw_url(@project, tree_join(diff_file.old_content_sha, diff_file.old_path), only_path: only_path)
  end

  def diff_file_blob_raw_path(diff_file)
    diff_file_blob_raw_url(diff_file, only_path: true)
  end

  def diff_file_old_blob_raw_path(diff_file)
    diff_file_old_blob_raw_url(diff_file, only_path: true)
  end

  def diff_file_html_data(project, diff_file_path, diff_commit_id)
    {
      blob_diff_path: project_blob_diff_path(project,
                                                       tree_join(diff_commit_id, diff_file_path)),
      view: diff_view
    }
  end

  def editable_diff?(diff_file)
    !diff_file.deleted_file? && @merge_request && @merge_request.source_project
  end

  def diff_file_changed_icon(diff_file)
    if diff_file.deleted_file?
      "file-deletion"
    elsif diff_file.new_file?
      "file-addition"
    else
      "file-modified"
    end
  end

  def diff_file_changed_icon_color(diff_file)
    if diff_file.deleted_file?
      "cred"
    elsif diff_file.new_file?
      "cgreen"
    end
  end

  def render_overflow_warning?(diffs_collection)
    diff_files = diffs_collection.raw_diff_files

    if diff_files.any?(&:too_large?)
      Gitlab::Metrics.add_event(:diffs_overflow_single_file_limits)
    end

    diff_files.overflow?.tap do |overflown|
      Gitlab::Metrics.add_event(:diffs_overflow_collection_limits) if overflown
    end
  end

  private

  def diff_btn(title, name, selected)
    params_copy = safe_params.dup
    params_copy[:view] = name

    # Always use HTML to handle case where JSON diff rendered this button
    params_copy.delete(:format)

    link_to url_for(params_copy), id: "#{name}-diff-btn", class: (selected ? 'btn active' : 'btn'), data: { view_type: name } do
      title
    end
  end

  def commit_diff_whitespace_link(project, commit, options)
    url = project_commit_path(project, commit.id, params_with_whitespace)
    toggle_whitespace_link(url, options)
  end

  def diff_merge_request_whitespace_link(project, merge_request, options)
    url = diffs_project_merge_request_path(project, merge_request, params_with_whitespace)
    toggle_whitespace_link(url, options)
  end

  def diff_compare_whitespace_link(project, from, to, options)
    url = project_compare_path(project, from, to, params_with_whitespace)
    toggle_whitespace_link(url, options)
  end

  def hide_whitespace?
    params[:w] == '1'
  end

  def params_with_whitespace
    hide_whitespace? ? request.query_parameters.except(:w) : request.query_parameters.merge(w: 1)
  end

  def toggle_whitespace_link(url, options)
    options[:class] = [*options[:class], 'btn btn-default'].join(' ')
    link_to "#{hide_whitespace? ? 'Show' : 'Hide'} whitespace changes", url, class: options[:class]
  end

  def diff_file_path_text(diff_file, max: 60)
    path = diff_file.new_path

    return path unless path.size > max && max > 3

    "...#{path[-(max - 3)..-1]}"
  end
end
