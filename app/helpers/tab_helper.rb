# frozen_string_literal: true

module TabHelper
  # Navigation tabs helper

  # Create a <gl-tabs> container
  #
  # Returns a `ul` element with classes that correspond to
  # the <gl-tabs/> component. Can be populated by
  # gl_tab_link_to elements.
  #
  # See more at: https://gitlab-org.gitlab.io/gitlab-ui/?path=/story/base-tabs--default
  def gl_tabs_nav(html_options = {}, &block)
    gl_tabs_classes = %w[nav gl-tabs-nav]

    html_options = html_options.merge(
      role: 'tablist',
      class: [*html_options[:class], gl_tabs_classes].join(' ')
    )

    content = capture(&block) if block
    content_tag(:ul, content, html_options)
  end

  # Create a <gl-tab> link
  #
  # When a tab is active it gets highlighted to indicate this is currently viewed tab.
  # Internally `current_page?` is called to determine if this is the current tab.
  #
  # Usage is the same as "link_to", with the following additional options:
  #
  # html_options - The html_options hash (default: {})
  #   :item_active - Overrides the default state focing the "active" css classes (optional).
  #
  def gl_tab_link_to(name = nil, options = {}, html_options = {}, &block)
    link_classes = %w[nav-link gl-tab-nav-item]
    active_link_classes = %w[active gl-tab-nav-item-active]

    if block
      # Shift params to skip the omitted "name" param
      html_options = options
      options = name
    end

    html_options = html_options.merge(
      role: 'tab',
      class: [*html_options[:class], link_classes].join(' ')
    )

    if gl_tab_link_to_active?(options, html_options)
      html_options[:class] = [*html_options[:class], active_link_classes].join(' ')
    end

    html_options = html_options.except(:item_active)
    extra_tab_classes = html_options.delete(:tab_class)
    tab_class = %w[nav-item].push(*extra_tab_classes)

    content_tag(:li, role: 'presentation', class: tab_class) do
      if block
        link_to(options, html_options, &block)
      else
        link_to(name, options, html_options)
      end
    end
  end

  # Creates a <gl-badge> for use inside tabs.
  #
  # html_options - The html_options hash (default: {})
  def gl_tab_counter_badge(count, html_options = {})
    gl_badge_tag(
      count,
      html_options.merge(
        class: ['gl-tab-counter-badge', *html_options[:class]]
      )
    )
  end

  # Navigation link helper
  #
  # Returns an `li` element with an 'active' class if the supplied
  # controller(s) and/or action(s) are currently active. The content of the
  # element is the value passed to the block.
  #
  # options - The options hash used to determine if the element is "active" (default: {})
  #           :controller   - One or more controller names to check, use path notation when namespaced (optional).
  #           :action       - One or more action names to check (optional).
  #           :path         - A shorthand path, such as 'dashboard#index', to check (optional).
  #           :html_options - Extra options to be passed to the list element (optional).
  # block   - An optional block that will become the contents of the returned
  #           `li` element.
  #
  # When both :controller and :action are specified, BOTH must match in order
  # to be marked as active. When only one is given, either can match.
  #
  # Examples
  #
  #   # Assuming we're on TreeController#show
  #
  #   # Controller matches, but action doesn't
  #   nav_link(controller: [:tree, :refs], action: :edit) { "Hello" }
  #   # => '<li>Hello</li>'
  #
  #   # Controller matches
  #   nav_link(controller: [:tree, :refs]) { "Hello" }
  #   # => '<li class="active">Hello</li>'
  #
  #   # Several paths
  #   nav_link(path: ['tree#show', 'profile#show']) { "Hello" }
  #   # => '<li class="active">Hello</li>'
  #
  #   # Shorthand path
  #   nav_link(path: 'tree#show') { "Hello" }
  #   # => '<li class="active">Hello</li>'
  #
  #   # Supplying custom options for the list element
  #   nav_link(controller: :tree, html_options: {class: 'home'}) { "Hello" }
  #   # => '<li class="home active">Hello</li>'
  #
  #   # For namespaced controllers like Admin::AppearancesController#show
  #
  #   # Controller and namespace matches
  #   nav_link(controller: 'admin/appearances') { "Hello" }
  #   # => '<li class="active">Hello</li>'
  #
  #   # Controller and namespace matches but action doesn't
  #   nav_link(controller: 'admin/appearances', action: :edit) { "Hello" }
  #   # => '<li>Hello</li>'
  #
  #   # Shorthand path with namespace
  #   nav_link(path: 'admin/appearances#show') { "Hello"}
  #   # => '<li class="active">Hello</li>'
  #
  #   # When `TreeController#index` is requested
  #   # => '<li>Hello</li>'
  #
  #   # Paths, controller and actions can be used at the same time
  #   nav_link(path: 'tree#show', controller: 'admin/appearances') { "Hello" }
  #
  #   nav_link(path: 'foo#bar', controller: 'tree') { "Hello" }
  #   nav_link(path: 'foo#bar', controller: 'tree', action: 'show') { "Hello" }
  #   nav_link(path: 'foo#bar', action: 'show') { "Hello" }
  #
  # Returns a list item element String
  def nav_link(options = {}, &block)
    klass = active_nav_link?(options) ? 'active' : ''

    # Add our custom class into the html_options, which may or may not exist
    # and which may or may not already have a :class key
    o = options.delete(:html_options) || {}
    o[:class] = [*o[:class], klass].join(' ')
    o[:class].strip!

    if block
      content_tag(:li, capture(&block), o)
    else
      content_tag(:li, nil, o)
    end
  end

  def active_nav_link?(options)
    controller = options.delete(:controller)
    action = options.delete(:action)

    route_matches_paths?(options.delete(:path)) ||
      route_matches_page_without_exclusion?(options.delete(:page), options.delete(:exclude_page)) ||
      route_matches_controllers_and_or_actions?(controller, action)
  end

  def current_path?(path)
    c, a, _ = path.split('#')
    current_controller?(c) && current_action?(a)
  end

  private

  def route_matches_paths?(paths)
    Array(paths).compact.any? do |single_path|
      current_path?(single_path)
    end
  end

  def route_matches_page_without_exclusion?(pages, exclude_page)
    return false unless route_matches_pages?(pages)
    return true unless exclude_page.present?

    !route_matches_pages?(exclude_page)
  end

  def route_matches_pages?(pages)
    Array(pages).compact.any? do |single_page|
      # We need to distinguish between Hash argument and other types of
      # arguments (for example String) in order to fix deprecation kwargs
      # warning.
      #
      # This can be refactored to
      #
      # current_page?(single_page)
      #
      # When we migrate to Ruby 3 or the Rails version contains the following:
      # https://github.com/rails/rails/commit/81d90d81d0ee1fc1a649ab705119a71f2d04c8a2
      if single_page.is_a?(Hash)
        current_page?(**single_page)
      else
        current_page?(single_page)
      end
    end
  end

  def route_matches_controllers_and_or_actions?(controller, action)
    if controller && action
      current_controller?(*controller) && current_action?(*action)
    else
      current_controller?(*controller) || current_action?(*action)
    end
  end

  def gl_tab_link_to_active?(options, html_options)
    return html_options[:item_active] if html_options.has_key?(:item_active)

    current_page?(options)
  end
end
