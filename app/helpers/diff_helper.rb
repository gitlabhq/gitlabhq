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
      diff_views = %w[inline parallel]
      diff_view = params[:view] || cookies[:diff_view]
      diff_view = diff_views.first unless diff_views.include?(diff_view)
      diff_view.to_sym
    end
  end

  def show_only_context_commits?
    !!params[:only_context_commits] || @merge_request.has_no_commits?
  end

  def diff_options
    options = { ignore_whitespace_change: hide_whitespace?, expanded: diffs_expanded?, use_extra_viewer_as_main: true }

    if action_name == 'diff_for_path' || action_name == 'diff_by_file_hash'
      options[:expanded] = true
      options[:paths] = params.values_at(:old_path, :new_path)
      options[:use_extra_viewer_as_main] = false

      if params[:file_identifier]&.include?('.ipynb')
        options[:max_patch_bytes_for_file_extension] = {
          '.ipynb' => 1.megabyte
        }
      end
    end

    options
  end

  def rapid_diffs?
    return false unless defined? current_user

    ::Feature.enabled?(:rapid_diffs, current_user, type: :wip)
  end

  def diff_match_line(old_pos, new_pos, text: '', view: :inline, bottom: false)
    content_line_class = %w[line_content match]
    content_line_class << 'parallel' if view == :parallel

    line_num_class = %w[diff-line-num unfold js-unfold]
    line_num_class << 'js-unfold-bottom' if bottom

    html = []

    expand_data = {}
    if bottom
      expand_data[:expand_next_line] = true
    else
      expand_data[:expand_prev_line] = true
    end

    if rapid_diffs?
      expand_button = content_tag(:button, '...', class: 'gl-bg-transparent gl-border-0 gl-p-0', data: { visible_when_loading: false, **expand_data })
      spinner = render(Pajamas::SpinnerComponent.new(size: :sm, class: 'gl-hidden gl-text-align-right', data: { visible_when_loading: true }))
      expand_html = content_tag(:div, [expand_button, spinner].join.html_safe, data: { expand_wrapper: true })
    else
      expand_html = '...'
    end

    if old_pos
      html << content_tag(:td, expand_html, class: [*line_num_class, 'old_line'], data: { linenumber: old_pos })
      html << content_tag(:td, text, class: [*content_line_class, 'left-side']) if view == :parallel
    end

    if new_pos
      html << content_tag(:td, expand_html, class: [*line_num_class, 'new_line'], data: { linenumber: new_pos })
      html << content_tag(:td, text, class: [*content_line_class, ('right-side' if view == :parallel)])
    end

    html.join.html_safe
  end

  def diff_nomappinginraw_line(line, first_line_num_class, second_line_num_class, content_line_class)
    css_class = ''
    css_class = 'old' if line.type == 'old-nomappinginraw'
    css_class = 'new' if line.type == 'new-nomappinginraw'

    html = [content_tag(:td, '', class: [*first_line_num_class, css_class])]
    html << content_tag(:td, '', class: [*second_line_num_class, css_class]) if second_line_num_class
    html << content_tag(:td, diff_line_content(line.rich_text), class: [*content_line_class, 'nomappinginraw', css_class])

    html.join.html_safe
  end

  def diff_line_content(line)
    if line.blank?
      "&nbsp;".html_safe
    elsif line.start_with?('+', '-', ' ')
      # `sub` and substring-ing would destroy HTML-safeness of `line`
      line[1, line.length]
    else
      line
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
    diff_btn(s_('Diffs|Inline'), 'inline', diff_view == :inline)
  end

  def parallel_diff_btn
    diff_btn(s_('Diffs|Side-by-side'), 'parallel', diff_view == :parallel)
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
    return '' unless compare_url

    link_text = [
      _('Compare'),
      ' ',
      content_tag(:span, Commit.truncate_sha(diff_file.old_blob.id), class: 'commit-sha'),
      '...',
      content_tag(:span, Commit.truncate_sha(diff_file.blob.id), class: 'commit-sha')
    ].join('').html_safe

    tooltip = _('Compare submodule commit revisions')
    link_button_to link_text, compare_url, class: 'has-tooltip submodule-compare', title: tooltip
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

  def diff_file_stats_data(diff_file)
    old_blob = diff_file.old_blob
    new_blob = diff_file.new_blob
    {
      old_size: old_blob&.size,
      new_size: new_blob&.size,
      added_lines: diff_file.added_lines,
      removed_lines: diff_file.removed_lines,
      viewer_name: diff_file.viewer.partial_name
    }
  end

  def editable_diff?(diff_file)
    !diff_file.deleted_file? && @merge_request && @merge_request.source_project
  end

  def render_overflow_warning?(diffs_collection)
    diffs_collection.overflow?.tap do |overflown|
      log_overflow_limits(diff_files: diffs_collection.raw_diff_files, collection_overflow: overflown)
    end
  end

  def apply_diff_view_cookie!
    return unless params[:view].present?

    set_secure_cookie(:diff_view, params.delete(:view), type: CookiesHelper::COOKIE_TYPE_PERMANENT)
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

  def conflicts(allow_tree_conflicts: false)
    unless merge_request.cannot_be_merged? && merge_request.source_branch_exists? && merge_request.target_branch_exists?
      return
    end

    conflicts_service = MergeRequests::Conflicts::ListService.new(merge_request, allow_tree_conflicts: allow_tree_conflicts)

    return unless allow_tree_conflicts || conflicts_service.can_be_resolved_in_ui?

    conflicts_service.conflicts.files.index_by(&:path)
  rescue Gitlab::Git::Conflict::Resolver::ConflictSideMissing
    # This exception is raised when changes on a fork isn't present on canonical repo yet.
    # We can't list conflicts until the canonical repo gets the references from the fork
    # which happens asynchronously when updating MR.
    #
    # Return empty hash to indicate that there are no conflicts.
    {}
  end

  def conflicts_with_types
    unless merge_request.cannot_be_merged? && merge_request.source_branch_exists? && merge_request.target_branch_exists?
      return
    end

    cached_conflicts_with_types do
      # We set skip_content to true since we don't really need the content to list the conflicts and their types
      conflicts_service = MergeRequests::Conflicts::ListService.new(
        merge_request,
        allow_tree_conflicts: true,
        skip_content: true
      )

      {}.tap do |h|
        conflicts_service.conflicts.files.each do |file|
          h[file.path] = {
            conflict_type: file.conflict_type,
            conflict_type_when_renamed: file.conflict_type(when_renamed: true)
          }
        end
      end
    end
  rescue Gitlab::Git::Conflict::Resolver::ConflictSideMissing
    # This exception is raised when changes on a fork isn't present on canonical repo yet.
    # We can't list conflicts until the canonical repo gets the references from the fork
    # which happens asynchronously when updating MR.
    #
    # Return empty hash to indicate that there are no conflicts.
    {}
  end

  def params_with_whitespace
    hide_whitespace? ? safe_params.except(:w) : safe_params.merge(w: 1)
  end

  private

  def cached_conflicts_with_types
    cache_key = "merge_request_#{merge_request.id}_conflicts_with_types"
    cache = Rails.cache.read(cache_key)
    source_branch_sha = merge_request.source_branch_sha
    target_branch_sha = merge_request.target_branch_sha

    if cache.blank? || cache[:source_sha] != source_branch_sha || cache[:target_sha] != target_branch_sha
      conflicts_files = yield

      cache = {
        source_sha: source_branch_sha,
        target_sha: target_branch_sha,
        conflicts: conflicts_files
      }

      Rails.cache.write(cache_key, cache)
    end

    cache[:conflicts]
  end

  def diff_btn(title, name, selected)
    params_copy = safe_params.dup
    params_copy[:view] = name

    # Always use HTML to handle case where JSON diff rendered this button
    params_copy.delete(:format)

    link_button_to url_for(params_copy), id: "#{name}-diff-btn", class: (selected ? 'selected' : ''), data: { view_type: name } do
      title
    end
  end

  def commit_diff_whitespace_link(project, commit, options)
    url = project_commit_path(project, commit.id, params_with_whitespace)
    toggle_whitespace_link(url, options)
  end

  def diff_compare_whitespace_link(project, from, to, options)
    url = project_compare_path(project, from, to, params_with_whitespace)
    toggle_whitespace_link(url, options)
  end

  def hide_whitespace?
    params[:w] == '1'
  end

  def toggle_whitespace_link(url, options)
    toggle_text = hide_whitespace? ? s_('Diffs|Show whitespace changes') : s_('Diffs|Hide whitespace changes')
    link_button_to toggle_text, url, class: options[:class]
  end

  def code_navigation_path(diffs)
    Gitlab::CodeNavigationPath.new(merge_request.project, merge_request.diff_head_sha)
  end

  def log_overflow_limits(diff_files:, collection_overflow:)
    Gitlab::Metrics.add_event(:diffs_overflow_single_file_limits) if diff_files.any?(&:too_large?)

    Gitlab::Metrics.add_event(:diffs_overflow_collection_limits) if collection_overflow
    Gitlab::Metrics.add_event(:diffs_overflow_max_bytes_limits) if diff_files.overflow_max_bytes?
    Gitlab::Metrics.add_event(:diffs_overflow_max_files_limits) if diff_files.overflow_max_files?
    Gitlab::Metrics.add_event(:diffs_overflow_max_lines_limits) if diff_files.overflow_max_lines?
    Gitlab::Metrics.add_event(:diffs_overflow_collapsed_bytes_limits) if diff_files.collapsed_safe_bytes?
    Gitlab::Metrics.add_event(:diffs_overflow_collapsed_files_limits) if diff_files.collapsed_safe_files?
    Gitlab::Metrics.add_event(:diffs_overflow_collapsed_lines_limits) if diff_files.collapsed_safe_lines?
  end
end
