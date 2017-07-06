module BreadcrumbsHelper
  def breadcrumbs_extra_links(text, link)
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
end
