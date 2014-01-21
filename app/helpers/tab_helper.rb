module TabHelper
  # Navigation link helper
  #
  # Returns an `li` element with an 'active' class if the supplied
  # controller(s) and/or action(s) are currently active. The content of the
  # element is the value passed to the block.
  #
  # options - The options hash used to determine if the element is "active" (default: {})
  #           :controller   - One or more controller names to check (optional).
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
  #   # Shorthand path
  #   nav_link(path: 'tree#show') { "Hello" }
  #   # => '<li class="active">Hello</li>'
  #
  #   # Supplying custom options for the list element
  #   nav_link(controller: :tree, html_options: {class: 'home'}) { "Hello" }
  #   # => '<li class="home active">Hello</li>'
  #
  # Returns a list item element String
  def nav_link(options = {}, &block)
    if path = options.delete(:path)
      if path.respond_to?(:each)
        c = path.map { |p| p.split('#').first }
        a = path.map { |p| p.split('#').last }
      else
        c, a, _ = path.split('#')
      end
    else
      c = options.delete(:controller)
      a = options.delete(:action)
    end

    if c && a
      # When given both options, make sure BOTH are active
      klass = current_controller?(*c) && current_action?(*a) ? 'active' : ''
    else
      # Otherwise check EITHER option
      klass = current_controller?(*c) || current_action?(*a) ? 'active' : ''
    end

    # Add our custom class into the html_options, which may or may not exist
    # and which may or may not already have a :class key
    o = options.delete(:html_options) || {}
    o[:class] ||= ''
    o[:class] += ' ' + klass
    o[:class].strip!

    if block_given?
      content_tag(:li, capture(&block), o)
    else
      content_tag(:li, nil, o)
    end
  end

  def project_tab_class
    return "active" if current_page?(controller: "/projects", action: :edit, id: @project)

    if ['services', 'hooks', 'deploy_keys', 'team_members'].include? controller.controller_name
     "active"
    end
  end

  def branches_tab_class
    if current_controller?(:protected_branches) ||
      current_controller?(:branches) ||
      current_page?(project_repository_path(@project))
      'active'
    end
  end

  # Use nav_tab for save controller/action  but different params
  def nav_tab key, value, &block
    o = {}
    o[:class] = ""

    if value.nil?
      o[:class] << " active" if params[key].blank?
    else
      o[:class] << " active" if params[key] == value
    end

    if block_given?
      content_tag(:li, capture(&block), o)
    else
      content_tag(:li, nil, o)
    end
  end
end
