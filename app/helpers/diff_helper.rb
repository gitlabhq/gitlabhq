module DiffHelper
  def allowed_diff_size
    if diff_hard_limit_enabled?
      Commit::DIFF_HARD_LIMIT_FILES
    else
      Commit::DIFF_SAFE_FILES
    end
  end

  def safe_diff_files(diffs)
    diffs.first(allowed_diff_size).map do |diff|
      Gitlab::Diff::File.new(diff)
    end
  end

  def show_diff_size_warning?(diffs)
    diffs.size > allowed_diff_size
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
    # [left_type, left_line_number, left_line_content, line_code, right_line_type, right_line_number, right_line_content]
    #
    diff_file.diff_lines.each do |line|

      full_line = line.text
      type = line.type
      line_code = generate_line_code(diff_file.file_path, line)
      line_new = line.new_pos
      line_old = line.old_pos

      next_line = diff_file.next_line(line.index)

      if next_line
        next_type = next_line.type
        next_line = next_line.text
      end

      line = [type, line_old, full_line, line_code, next_type, line_new]
      if type == 'match' || type.nil?
        # line in the right panel is the same as in the left one
        line = [type, line_old, full_line, line_code, type, line_new, full_line]
        lines.push(line)
      elsif type == 'old'
        if next_type == 'new'
          # Left side has text removed, right side has text added
          line.push(next_line)
          lines.push(line)
          skip_next = true
        elsif next_type == 'old' || next_type.nil?
          # Left side has text removed, right side doesn't have any change
          line.pop # remove the newline
          line.push(nil) # no line number on the right panel
          line.push("&nbsp;") # empty line on the right panel
          lines.push(line)
        end
      elsif type == 'new'
        if skip_next
          # Change has been already included in previous line so no need to do it again
          skip_next = false
          next
        else
          # Change is only on the right side, left side has no change
          line = [nil, nil, "&nbsp;", line_code, type, line_new, full_line]
          lines.push(line)
        end
      end
    end
    lines
  end

  def unfold_bottom_class(bottom)
    (bottom) ? 'js-unfold-bottom' : ''
  end

  def diff_line_content(line)
    if line.blank?
      " &nbsp;"
    else
      line
    end
  end
end
