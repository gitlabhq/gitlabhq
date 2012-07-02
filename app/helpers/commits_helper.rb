module CommitsHelper
  def commit_msg_with_link_to_issues(project, message)
    return '' unless message
    out = ''
    message.split(/(#[0-9]+)/m).each do |m|
      if m =~ /(#([0-9]+))/m
        begin
          issue = project.issues.find($2)
          out += link_to($1, project_issue_path(project, $2))
        rescue
          out += $1
        end
      else
        out += m
      end
    end
    preserve out
  end

  def identification_type(line)
    if line[0] == "+"
      "new"
    elsif line[0] == "-"
      "old"
    else
      nil
    end
  end

  def build_line_anchor(index, line_new, line_old)
    "#{index}_#{line_old}_#{line_new}"
  end

  def each_diff_line(diff_arr, index)
    line_old = 1
    line_new = 1
    type = nil
    
    lines_arr = inline_diff diff_arr
    #lines_arr = diff_arr
    lines_arr.each do |line|
      next if line.match(/^\-\-\- \/dev\/null/)
      next if line.match(/^\+\+\+ \/dev\/null/)
      next if line.match(/^\-\-\- a/)
      next if line.match(/^\+\+\+ b/)

      full_line = html_escape(line.gsub(/\n/, ''))

      full_line.gsub!("#!idiff-start!#", "<span class='idiff'>")
      full_line.gsub!("#!idiff-finish!#", "</span>")

      if line.match(/^@@ -/)
        type = "match"

        line_old = line.match(/\-[0-9]*/)[0].to_i.abs rescue 0
        line_new = line.match(/\+[0-9]*/)[0].to_i.abs rescue 0

        next if line_old == 1 && line_new == 1 #top of file
        yield(full_line, type, nil, nil, nil)
        next
      else
        type = identification_type(line)
        line_code = build_line_anchor(index, line_new, line_old)
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

  def image_diff_class(diff)
    if diff.deleted_file
      "diff_image_removed"
    elsif diff.new_file
      "diff_image_added"
    else
      nil
    end
  end

  def inline_diff diff_arr
    chain_of_first_symbols = ""
    diff_arr.each_with_index do |line, i|
      chain_of_first_symbols += line[0]
    end
    chain_of_first_symbols.gsub!(/[^\-\+]/, "#")
    
    offset = 0
    indexes = []
    while index = chain_of_first_symbols.index("#-+#", offset)
      indexes << index
      offset = index + 1
    end

    indexes.each do |index|
      first_line = diff_arr[index+1]
      second_line = diff_arr[index+2]
      max_length = [first_line.size, second_line.size].max
      
      first_the_same_symbols = 0
      (0..max_length + 1).each do |i|
        first_the_same_symbols = i - 1
        if first_line[i] != second_line[i] && i > 0
          break
        end
      end
      first_token = first_line[0..first_the_same_symbols][1..-1]
      
      diff_arr[index+1].sub!(first_token, first_token + "#!idiff-start!#")
      diff_arr[index+2].sub!(first_token, first_token + "#!idiff-start!#")
      
      last_the_same_symbols = 0
      (1..max_length + 1).each do |i|
        last_the_same_symbols = -i
        if first_line[-i] != second_line[-i]
          break
        end
      end
      last_the_same_symbols += 1
      last_token = first_line[last_the_same_symbols..-1]

      diff_arr[index+1].sub!(/#{last_token}$/, "#!idiff-finish!#" + last_token)
      diff_arr[index+2].sub!(/#{last_token}$/, "#!idiff-finish!#" + last_token)
    end
    diff_arr
  end
end
