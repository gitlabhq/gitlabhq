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

  def fluid_layout(enabled = false)
    if @fluid_layout.nil?
      @fluid_layout = (current_user && current_user.layout == "fluid") || enabled
    else
      @fluid_layout
    end
  end

  def blank_container(enabled = false)
    if @blank_container.nil?
      @blank_container = enabled
    else
      @blank_container
    end
  end

  def container_class
    css_class = "container-fluid"

    unless fluid_layout
      css_class += " container-limited"
    end

    if blank_container
      css_class += " container-blank"
    end

    css_class
  end
end
