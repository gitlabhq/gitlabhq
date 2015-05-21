module DiffHelper
  def allowed_diff_size
    if diff_hard_limit_enabled?
      Commit::DIFF_HARD_LIMIT_FILES
    else
      Commit::DIFF_SAFE_FILES
    end
  end

  def allowed_diff_lines
    if diff_hard_limit_enabled?
      Commit::DIFF_HARD_LIMIT_LINES
    else
      Commit::DIFF_SAFE_LINES
    end
  end

  def safe_diff_files(diffs)
    lines = 0
    safe_files = []
    diffs.first(allowed_diff_size).each do |diff|
      lines += diff.diff.lines.count
      break if lines > allowed_diff_lines
      safe_files << Gitlab::Diff::File.new(diff)
    end
    safe_files
  end

  def diff_hard_limit_enabled?
    # Enabling hard limit allows user to see more diff information
    if params[:force_show_diff].present?
      true
    else
      false
    end
  end

  def generate_line_code(file_path, line)
    Gitlab::Diff::LineCode.generate(file_path, line.new_pos, line.old_pos)
  end

  def parallel_diff(diff_file, index)
    lines = []
    skip_next = false

    # Building array of lines
    #
    # [
    # left_type, left_line_number, left_line_content, left_line_code,
    # right_line_type, right_line_number, right_line_content, right_line_code
    # ]
    #
    diff_file.diff_lines.each do |line|

      full_line = line.text
      type = line.type
      line_code = generate_line_code(diff_file.file_path, line)
      line_new = line.new_pos
      line_old = line.old_pos

      next_line = diff_file.next_line(line.index)

      if next_line
        next_line_code = generate_line_code(diff_file.file_path, next_line)
        next_type = next_line.type
        next_line = next_line.text
      end

      if type == 'match' || type.nil?
        # line in the right panel is the same as in the left one
        line = [type, line_old, full_line, line_code, type, line_new, full_line, line_code]
        lines.push(line)
      elsif type == 'old'
        if next_type == 'new'
          # Left side has text removed, right side has text added
          line = [type, line_old, full_line, line_code, next_type, line_new, next_line, next_line_code]
          lines.push(line)
          skip_next = true
        elsif next_type == 'old' || next_type.nil?
          # Left side has text removed, right side doesn't have any change
          # No next line code, no new line number, no new line text
          line = [type, line_old, full_line, line_code, next_type, nil, "&nbsp;", nil]
          lines.push(line)
        end
      elsif type == 'new'
        if skip_next
          # Change has been already included in previous line so no need to do it again
          skip_next = false
          next
        else
          # Change is only on the right side, left side has no change
          line = [nil, nil, "&nbsp;", line_code, type, line_new, full_line, line_code]
          lines.push(line)
        end
      end
    end
    lines
  end

  def unfold_bottom_class(bottom)
    (bottom) ? 'js-unfold-bottom' : ''
  end

  def unfold_class(unfold)
    (unfold) ? 'unfold js-unfold' : ''
  end

  def diff_line_content(line)
    if line.blank?
      " &nbsp;"
    else
      line
    end
  end

  def line_comments
    @line_comments ||= @line_notes.select(&:active?).group_by(&:line_code)
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
    params_copy = params.dup
    params_copy[:view] = 'inline'
    # Always use HTML to handle case where JSON diff rendered this button
    params_copy.delete(:format)

    link_to url_for(params_copy), id: "commit-diff-viewtype", class: (params[:view] != 'parallel' ? 'btn btn-sm active' : 'btn btn-sm') do
      'Inline'
    end
  end

  def parallel_diff_btn
    params_copy = params.dup
    params_copy[:view] = 'parallel'
    # Always use HTML to handle case where JSON diff rendered this button
    params_copy.delete(:format)

    link_to url_for(params_copy), id: "commit-diff-viewtype", class: (params[:view] == 'parallel' ? 'btn active btn-sm' : 'btn btn-sm') do
      'Side-by-side'
    end
  end

  def submodule_link(blob, ref, repository = @repository)
    tree, commit = submodule_links(blob, ref, repository)
    commit_id = if commit.nil?
                  blob.id[0..10]
                else
                  link_to "#{blob.id[0..10]}", commit
                end

    [
      content_tag(:span, link_to(truncate(blob.name, length: 40), tree)),
      '@',
      content_tag(:span, commit_id, class: 'monospace'),
    ].join(' ').html_safe
  end
end
