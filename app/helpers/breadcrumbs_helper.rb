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
    content_tag :li, link, class: 'gl-breadcrumb-item gl-inline-flex'
  end

  def add_to_breadcrumb_collapsed_links(link, location: :before)
    @breadcrumb_collapsed_links ||= {}
    @breadcrumb_collapsed_links[location] ||= []
    @breadcrumb_collapsed_links[location] << link
  end

  def push_to_schema_breadcrumb(text, href, avatar = nil)
    schema_breadcrumb_list.push({ text: text, href: href, avatar: avatar })
  end

  def schema_breadcrumb_json
    {
      '@context': 'https://schema.org',
      '@type': 'BreadcrumbList',
      itemListElement: build_item_list_elements&.map&.with_index do |item, index|
        {
          '@type' => 'ListItem',
          'position' => index + 1,
          'name' => item[:text],
          'item' => ensure_absolute_url(item[:href])
        }
      end
    }.to_json
  end

  def breadcrumbs_as_json
    schema_breadcrumb_list.map do |breadcrumb|
      {
        text: breadcrumb[:text],
        href: breadcrumb[:href],
        avatarPath: breadcrumb[:avatar]
      }
    end.to_json
  end

  private

  def schema_breadcrumb_list
    @schema_breadcrumb_list ||= []
  end

  def build_item_list_elements
    last_element = schema_breadcrumb_list.pop

    if @breadcrumbs_extra_links&.any?
      @breadcrumbs_extra_links.each do |el|
        push_to_schema_breadcrumb(el[:text], el[:link])
      end
    end

    if @breadcrumb_collapsed_links&.[](:after)&.any?
      @breadcrumb_collapsed_links[:after].each do |el|
        push_to_schema_breadcrumb(el[:text], el[:href], el[:avatar_url])
      end
    end

    schema_breadcrumb_list.push(last_element) if last_element
    schema_breadcrumb_list
  end

  def ensure_absolute_url(link)
    url = URI.parse(link)
    url.absolute? ? link : URI.join(request.base_url, link).to_s
  rescue URI::InvalidURIError
    "#{request.base_url}#{request.path}"
  end
end
