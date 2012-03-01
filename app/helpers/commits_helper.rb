module CommitsHelper
  def old_line_number(line, i)

  end

  def new_line_number(line, i)

  end

  def more_commits_link
    offset = params[:offset] || 0
    limit = params[:limit] || 100
    link_to "More", project_commits_path(@project, :offset =>  offset.to_i + limit.to_i, :limit => limit),
      :remote => true, :class => "lite_button vm", :style => "text-align:center; width:930px; ", :id => "more-commits-link"
  end

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

  def diff_line_class(line)
    if line[0] == "+"
      "new"
    elsif line[0] == "-"
      "old"
    else
      nil
    end
  end

  def build_line_code(line, index, line_new, line_old)
    "#{index}_#{line_old}_#{line_new}"
  end

  def each_diff_line(diff_arr, index)
    line_old = 1
    line_new = 1
    type = nil

    lines_arr = diff_arr
    lines_arr.each do |line|
      next if line.match(/^\-\-\- \/dev\/null/)
      next if line.match(/^\+\+\+ \/dev\/null/)
      next if line.match(/^\-\-\- a/)
      next if line.match(/^\+\+\+ b/)

      full_line = html_escape(line.gsub(/\n/, '')).force_encoding("UTF-8")

      if line.match(/^@@ -/)
        type = "match"

        line_old = line.match(/\-[0-9]*/)[0].to_i.abs rescue 0
        line_new = line.match(/\+[0-9]*/)[0].to_i.abs rescue 0
                
        next if line_old == 1 && line_new == 1
        yield(line, type, nil, nil, nil)
        next
      else
        type = diff_line_class(line)
        line_code = build_line_code(line, index, line_new, line_old)
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
end
