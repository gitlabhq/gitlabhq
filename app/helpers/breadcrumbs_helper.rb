module BreadcrumbsHelper
  def add_to_breadcrumbs(text, link)
    @breadcrumbs_extra_links ||= []
    @breadcrumbs_extra_links.push({
      text: text,
      link: link
    })
  end

  def breadcrumb_title_link
    return @breadcrumb_link if @breadcrumb_link

    if controller.available_action?(:index)
      url_for(action: "index")
    else
      request.path
    end
  end

  def breadcrumb_title(title)
    return if defined?(@breadcrumb_title)

    @breadcrumb_title = title
  end
end
