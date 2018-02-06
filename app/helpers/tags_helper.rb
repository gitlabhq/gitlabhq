module TagsHelper
  def tag_path(tag)
    "/tags/#{tag}"
  end

  def filter_tags_path(options = {})
    exist_opts = {
      search: params[:search],
      sort: params[:sort]
    }

    options = exist_opts.merge(options)
    project_tags_path(@project, @id, options)
  end

  def tag_list(project)
    html = ''
    project.tag_list.each do |tag|
      html << link_to(tag, tag_path(tag))
    end

    html.html_safe
  end

  def protected_tag?(project, tag)
    ProtectedTag.protected?(project, tag.name)
  end
end
