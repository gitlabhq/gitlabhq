# frozen_string_literal: true

module DiffHelper
  def mark_inline_diffs(old_line, new_line)
    old_diffs, new_diffs = Gitlab::Diff::InlineDiff.new(old_line, new_line).inline_diffs

    marked_old_line = Gitlab::Diff::InlineDiffMarker.new(old_line).mark(old_diffs)
    marked_new_line = Gitlab::Diff::InlineDiffMarker.new(new_line).mark(new_diffs)

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

  def show_only_context_commits?
    !!params[:only_context_commits] || @merge_request&.commits&.empty?
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
        line[1, line.length]
      else
        line
      end
    end
  end

  def diff_link_number(line_type, match, text)
    line_type == match ? " " : text
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
    urls = submodule_links(blob, ref, repository)

    folder_name = truncate(blob.name, length: 40)
    folder_name = link_to(folder_name, urls.web) if urls&.web

    commit_id = Commit.truncate_sha(blob.id)
    commit_id = link_to(commit_id, urls.tree) if urls&.tree

    [
      content_tag(:span, folder_name),
      '@',
      content_tag(:span, commit_id, class: 'commit-sha')
    ].join(' ').html_safe
  end

  def submodule_diff_compare_link(diff_file)
    compare_url = submodule_links(diff_file.blob, diff_file.content_sha, diff_file.repository, diff_file)&.compare

    link = ""

    if compare_url

      link_text = [
          _('Compare'),
          ' ',
          content_tag(:span, Commit.truncate_sha(diff_file.old_blob.id), class: 'commit-sha'),
          '...',
          content_tag(:span, Commit.truncate_sha(diff_file.blob.id), class: 'commit-sha')
        ].join('').html_safe

      tooltip = _('Compare submodule commit revisions')
      link = content_tag(:span, link_to(link_text, compare_url, class: 'btn gl-button has-tooltip', title: tooltip), class: 'submodule-compare')
    end

    link
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
      blob_diff_path: project_blob_diff_path(project, tree_join(diff_commit_id, diff_file_path)),
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
    diffs_collection.overflow?.tap do |overflown|
      log_overflow_limits(diff_files: diffs_collection.raw_diff_files, collection_overflow: overflown)
    end
  end

  def apply_diff_view_cookie!
    set_secure_cookie(:diff_view, params.delete(:view), type: CookiesHelper::COOKIE_TYPE_PERMANENT) if params[:view].present?
  end

  def collapsed_diff_url(diff_file)
    url_for(
      safe_params.merge(
        action: :diff_for_path,
        old_path: diff_file.old_path,
        new_path: diff_file.new_path,
        file_identifier: diff_file.file_identifier
      )
    )
  end

  # As the fork suggestion button is identical every time, we cache it for a full page load
  def render_fork_suggestion
    return unless current_user

    strong_memoize(:fork_suggestion) do
      render partial: "projects/fork_suggestion"
    end
  end

  private

  def diff_btn(title, name, selected)
    params_copy = safe_params.dup
    params_copy[:view] = name

    # Always use HTML to handle case where JSON diff rendered this button
    params_copy.delete(:format)

    link_to url_for(params_copy), id: "#{name}-diff-btn", class: (selected ? 'btn gl-button btn-default selected' : 'btn gl-button btn-default'), data: { view_type: name } do
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
    options[:class] = [*options[:class], 'btn gl-button btn-default'].join(' ')
    link_to "#{hide_whitespace? ? 'Show' : 'Hide'} whitespace changes", url, class: options[:class]
  end

  def diff_file_path_text(diff_file, max: 60)
    path = diff_file.new_path

    return path unless path.size > max && max > 3

    "...#{path[-(max - 3)..-1]}"
  end

  def code_navigation_path(diffs)
    Gitlab::CodeNavigationPath.new(merge_request.project, merge_request.diff_head_sha)
  end

  def conflicts
    return unless options[:merge_ref_head_diff]

    conflicts_service = MergeRequests::Conflicts::ListService.new(merge_request) # rubocop:disable CodeReuse/ServiceClass

    return unless conflicts_service.can_be_resolved_in_ui?

    conflicts_service.conflicts.files.index_by(&:our_path)
  end

  def log_overflow_limits(diff_files:, collection_overflow:)
    if diff_files.any?(&:too_large?)
      Gitlab::Metrics.add_event(:diffs_overflow_single_file_limits)
    end

    Gitlab::Metrics.add_event(:diffs_overflow_collection_limits) if collection_overflow
    Gitlab::Metrics.add_event(:diffs_overflow_max_bytes_limits) if diff_files.overflow_max_bytes?
    Gitlab::Metrics.add_event(:diffs_overflow_max_files_limits) if diff_files.overflow_max_files?
    Gitlab::Metrics.add_event(:diffs_overflow_max_lines_limits) if diff_files.overflow_max_lines?
    Gitlab::Metrics.add_event(:diffs_overflow_collapsed_bytes_limits) if diff_files.collapsed_safe_bytes?
    Gitlab::Metrics.add_event(:diffs_overflow_collapsed_files_limits) if diff_files.collapsed_safe_files?
    Gitlab::Metrics.add_event(:diffs_overflow_collapsed_lines_limits) if diff_files.collapsed_safe_lines?
  end
end
