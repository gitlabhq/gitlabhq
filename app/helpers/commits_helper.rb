module CommitsHelper
  include Utils::CharEncode

  def old_line_number(line, i)

  end

  def new_line_number(line, i)

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

  def more_commits_link
    offset = params[:offset] || 0
    limit = params[:limit] || 100
    link_to "More", project_commits_path(@project, :offset =>  offset.to_i + limit.to_i, :limit => limit),
      :remote => true, :class => "lite_button vm", :style => "text-align:center; width:930px; ", :id => "more-commits-link"
  end
end
