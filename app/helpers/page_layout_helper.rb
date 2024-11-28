# frozen_string_literal: true

module PageLayoutHelper
  include Gitlab::Utils::StrongMemoize

  def page_title(*titles)
    @page_title ||= []

    @page_title.push(*titles.compact) if titles.any?

    if titles.any? && !defined?(@breadcrumb_title)
      @breadcrumb_title = @page_title.last
    end

    # Segments are separated by middot
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
      sanitize(@page_description.truncate_words(30), tags: [])
    end
  end

  def page_canonical_link(link = nil)
    if link
      @page_canonical_link = link
    else
      @page_canonical_link ||= generic_canonical_url
    end
  end

  def favicon
    Gitlab::Favicon.main
  end

  def page_image
    default = image_url('twitter_card.jpg')

    subject = @project || @user || @group

    image = subject.avatar_url(only_path: false) if subject.present?
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
    tags = []

    page_card_attributes.each_with_index do |pair, i|
      tags << tag.meta(property: "twitter:label#{i + 1}", content: pair[0])
      tags << tag.meta(property: "twitter:data#{i + 1}",  content: pair[1])
    end

    tags.join.html_safe
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

  # This helper ensures there is always a default `Gitlab::SearchContext` available
  # to all controller that use the application layout.
  def search_context
    strong_memoize(:search_context) do
      next super if defined?(super)

      Gitlab::SearchContext::Builder.new(controller.view_context).build!
    end
  end

  def fluid_layout
    @force_fluid_layout == true || (current_user && current_user.layout == "fluid")
  end

  def blank_container(enabled = false)
    if @blank_container.nil?
      @blank_container = enabled
    else
      @blank_container
    end
  end

  def container_class
    css_class = ["container-fluid"]

    unless fluid_layout
      css_class << "container-limited"
    end

    if blank_container
      css_class << "container-blank"
    end

    css_class.join(' ')
  end

  def full_content_class
    "#{container_class} #{@content_class}"
  end

  def page_itemtype(itemtype = nil)
    if itemtype
      @page_itemtype = { itemscope: true, itemtype: itemtype }
    else
      @page_itemtype || {}
    end
  end

  def user_status_properties(user)
    default_properties = {
      current_emoji: '',
      current_message: '',
      default_emoji: UserStatus::DEFAULT_EMOJI
    }

    return default_properties unless user&.status

    default_properties.merge({
      current_emoji: user.status.emoji.to_s,
      current_message: user.status.message.to_s,
      current_availability: user.status.availability.to_s,
      current_clear_status_after: user_clear_status_at(user)
    })
  end

  private

  def generic_canonical_url
    strong_memoize(:generic_canonical_url) do
      next unless request.get? || request.head?
      next unless generate_generic_canonical_url?

      # Request#url builds the url without the trailing slash
      request.url
    end
  end

  def generate_generic_canonical_url?
    # For the main domain it doesn't matter whether there is
    # a trailing slash or not, they're not considered different
    # pages
    return false if request.path == '/'

    # We only need to generate the canonical url when the request has a trailing
    # slash. In the request object, only the `original_fullpath` and
    # `original_url` keep the slash if it's present. Both `path` and
    # `fullpath` would return the path without the slash.
    # Therefore, we need to process `original_fullpath`
    request.original_fullpath.sub(request.path, '')[0] == '/'
  end
end
