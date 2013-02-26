module CommitsHelper
  def identification_type(line)
    if line[0] == "+"
      "new"
    elsif line[0] == "-"
      "old"
    else
      nil
    end
  end

  def build_line_anchor(diff, line_new, line_old)
    "#{hexdigest(diff.new_path)}_#{line_old}_#{line_new}"
  end

  def each_diff_line(diff, index)
    diff_arr = diff.diff.lines.to_a

    line_old = 1
    line_new = 1
    type = nil

    lines_arr = ::Gitlab::InlineDiff.processing diff_arr
    lines_arr.each do |line|
      next if line.match(/^\-\-\- \/dev\/null/)
      next if line.match(/^\+\+\+ \/dev\/null/)
      next if line.match(/^\-\-\- a/)
      next if line.match(/^\+\+\+ b/)

      full_line = html_escape(line.gsub(/\n/, ''))
      full_line = ::Gitlab::InlineDiff.replace_markers full_line

      if line.match(/^@@ -/)
        type = "match"

        line_old = line.match(/\-[0-9]*/)[0].to_i.abs rescue 0
        line_new = line.match(/\+[0-9]*/)[0].to_i.abs rescue 0

        next if line_old == 1 && line_new == 1 #top of file
        yield(full_line, type, nil, nil, nil)
        next
      else
        type = identification_type(line)
        line_code = build_line_anchor(diff, line_new, line_old)
        yield(full_line, type, line_code, line_new, line_old)
      end


      if line[0] == "+"
        line_new += 1
      elsif line[0] == "-"
        line_old += 1
      else
        line_new += 1
        line_old += 1
      end
    end
  end

  def each_diff_line_near(diff, index, expected_line_code)
    max_number_of_lines = 16

    prev_match_line = nil
    prev_lines = []

    each_diff_line(diff, index) do |full_line, type, line_code, line_new, line_old|
      line = [full_line, type, line_code, line_new, line_old]
      if line_code != expected_line_code
        if type == "match"
          prev_lines.clear
          prev_match_line = line
        else
          prev_lines.push(line)
          prev_lines.shift if prev_lines.length >= max_number_of_lines
        end
      else
        yield(prev_match_line) if !prev_match_line.nil?
        prev_lines.each { |ln| yield(ln) }
        yield(line)
        break
      end
    end
  end

  def image_diff_class(diff)
    if diff.deleted_file
      "deleted"
    elsif diff.new_file
      "added"
    else
      nil
    end
  end

  def commit_to_html commit
    if commit.model
      escape_javascript(render 'commits/commit', commit: commit)
    end
  end

  def diff_line_content(line)
    if line.blank?
      " &nbsp;"
    else
      line
    end
  end
end
