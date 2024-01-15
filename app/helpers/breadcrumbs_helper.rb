# frozen_string_literal: true

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

    request.fullpath
  end

  def breadcrumb_title(title)
    return if defined?(@breadcrumb_title)

    @breadcrumb_title = title
  end

  def breadcrumb_list_item(link)
    content_tag :li, link, class: 'gl-breadcrumb-item gl-display-inline-flex'
  end

  def add_to_breadcrumb_collapsed_links(link, location: :before)
    @breadcrumb_collapsed_links ||= {}
    @breadcrumb_collapsed_links[location] ||= []
    @breadcrumb_collapsed_links[location] << link
  end

  def push_to_schema_breadcrumb(text, link)
    list_item = schema_list_item(text, link, schema_breadcrumb_list.size + 1)

    schema_breadcrumb_list.push(list_item)
  end

  def schema_breadcrumb_json
    {
      '@context': 'https://schema.org',
      '@type': 'BreadcrumbList',
      'itemListElement': build_item_list_elements
    }.to_json
  end

  private

  def schema_breadcrumb_list
    @schema_breadcrumb_list ||= []
  end

  def build_item_list_elements
    return @schema_breadcrumb_list unless @breadcrumbs_extra_links&.any?

    last_element = schema_breadcrumb_list.pop

    @breadcrumbs_extra_links.each do |el|
      push_to_schema_breadcrumb(el[:text], el[:link])
    end

    last_element['position'] = schema_breadcrumb_list.last['position'] + 1
    schema_breadcrumb_list.push(last_element)
  end

  def schema_list_item(text, link, position)
    {
      '@type' => 'ListItem',
      'position' => position,
      'name' => text,
      'item' => ensure_absolute_link(link)
    }
  end

  def ensure_absolute_link(link)
    url = URI.parse(link)
    url.absolute? ? link : URI.join(request.base_url, link).to_s
  rescue URI::InvalidURIError
    "#{request.base_url}#{request.path}"
  end
end
