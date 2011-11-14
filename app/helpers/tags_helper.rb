module TagsHelper
  def tag_path tag
    "/tags/#{tag}"
  end

  def tag_list project
    html = ''
    project.tag_list.each do |tag|
      html += link_to tag, tag_path(tag)
    end

    html.html_safe
  end
end
