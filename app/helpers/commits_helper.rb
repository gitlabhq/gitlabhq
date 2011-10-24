module CommitsHelper
  def diff_line(line, line_new = 0, line_old = 0)
    full_line = html_escape(line.gsub(/\n/, ''))
    color = if line[0] == "+" 
              full_line = "<span class=\"old_line\">&nbsp;</span><span class=\"new_line\">#{line_new}</span> " + full_line
              "#DFD"
            elsif line[0] == "-" 
              full_line = "<span class=\"old_line\">#{line_old}</span><span class=\"new_line\">&nbsp;</span> " + full_line
              "#FDD"
            else 
              full_line = "<span class=\"old_line\">#{line_old}</span><span class=\"new_line\">#{line_new}</span> " + full_line
              "none"
            end

    raw "<div style=\"white-space:pre;background:#{color};\">#{full_line}</div>"
  end

  def more_commits_link
    offset = params[:offset] || 0
    limit = params[:limit] || 100
    link_to "More", project_commits_path(@project, :offset =>  offset.to_i + limit.to_i, :limit => limit),
      :remote => true, :class => "lite_button vm", :style => "text-align:center; width:930px; ", :id => "more-commits-link"
  end
end
