module PageLayoutHelper
  def page_title(*titles)
    @page_title ||= []

    @page_title.push(*titles.compact) if titles.any?

    @page_title.join(" | ")
  end

  def header_title(title = nil, title_url = nil)
    if title
      @header_title     = title
      @header_title_url = title_url
    else
      @header_title_url ? link_to(@header_title, @header_title_url) : @header_title
    end
  end

  def sidebar(name = nil)
    if name
      @sidebar = name
    else
      @sidebar
    end
  end
end
