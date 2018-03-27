module PageLayoutHelper
  def page_title(*titles)
    @page_title ||= []

    @page_title.push(*titles.compact) if titles.any?

    if titles.any? && !defined?(@breadcrumb_title)
      @breadcrumb_title = @page_title.last
    end

    # Segments are seperated by middot
    @page_title.join(" · ")
  end

  # Define or get a description for the current page
  #
  # description - String (default: nil)
  #
  # If this helper is called multiple times with an argument, only the last
  # description will be returned when called without an argument. Descriptions
  # have newlines replaced with spaces and all HTML tags are sanitized.
  #
  # Examples:
  #
  #   page_description # => "GitLab Community Edition"
  #   page_description("Foo")
  #   page_description # => "Foo"
  #
  #   page_description("<b>Bar</b>\nBaz")
  #   page_description # => "Bar Baz"
  #
  # Returns an HTML-safe String.
  def page_description(description = nil)
    if description.present?
      @page_description = description.squish
    elsif @page_description.present?
      sanitize(@page_description, tags: []).truncate_words(30)
    end
  end

  def favicon
    return 'favicon-yellow.ico' if ENV['CANARY'] == 'true'
    return 'favicon-blue.ico' if Rails.env.development?
    'favicon.ico'
  end

  def page_image
    default = image_url('gitlab_logo.png')

    subject = @project || @user || @group

    image = subject.avatar_url if subject.present?
    image || default
  end

  # Define or get attributes to be used as Twitter card metadata
  #
  # map - Hash of label => data pairs. Keys become labels, values become data
  #
  # Raises ArgumentError if given more than two attributes
  def page_card_attributes(map = {})
    raise ArgumentError, 'cannot provide more than two attributes' if map.length > 2

    @page_card_attributes ||= {}
    @page_card_attributes = map.reject { |_, v| v.blank? } if map.present?
    @page_card_attributes
  end

  def page_card_meta_tags
    tags = ''

    page_card_attributes.each_with_index do |pair, i|
      tags << tag(:meta, property: "twitter:label#{i + 1}", content: pair[0])
      tags << tag(:meta, property: "twitter:data#{i + 1}",  content: pair[1])
    end

    tags.html_safe
  end

  def header_title(title = nil, title_url = nil)
    if title
      @header_title     = title
      @header_title_url = title_url
    else
      return @header_title unless @header_title_url

      breadcrumb_list_item(link_to(@header_title, @header_title_url))
    end
  end

  def sidebar(name = nil)
    if name
      @sidebar = name
    else
      @sidebar
    end
  end

  def nav(name = nil)
    if name
      @nav = name
    else
      @nav
    end
  end

  def fluid_layout
    current_user && current_user.layout == "fluid"
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
