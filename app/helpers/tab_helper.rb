module TabHelper
  # Navigation link helper
  #
  # Returns an `li` element with an 'active' class if the supplied
  # controller(s) and/or action(s) currently active. The contents of the
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
      c, a, _ = path.split('#')
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

  def tab_class(tab_key)
    active = case tab_key

             # Project Area
             when :wall; wall_tab?
             when :wiki; controller.controller_name == "wikis"
             when :network; current_page?(controller: "projects", action: "graph", id: @project)
             when :merge_requests; controller.controller_name == "merge_requests"

             # Dashboard Area
             when :help; controller.controller_name == "help"
             when :search; current_page?(search_path)
             when :dash_issues; current_page?(dashboard_issues_path)
             when :dash_mr; current_page?(dashboard_merge_requests_path)
             when :root; current_page?(dashboard_path) || current_page?(root_path)

             # Profile Area
             when :profile;  current_page?(controller: "profile", action: :show)
             when :history;  current_page?(controller: "profile", action: :history)
             when :account;  current_page?(controller: "profile", action: :account)
             when :token;    current_page?(controller: "profile", action: :token)
             when :design;   current_page?(controller: "profile", action: :design)
             when :ssh_keys; controller.controller_name == "keys"

             # Admin Area
             when :admin_root;     controller.controller_name == "dashboard"
             when :admin_users;    controller.controller_name == 'users'
             when :admin_projects; controller.controller_name == "projects"
             when :admin_hooks;    controller.controller_name == 'hooks'
             when :admin_resque;   controller.controller_name == 'resque'
             when :admin_logs;   controller.controller_name == 'logs'

             else
               false
             end
    active ? "active" : nil
  end

  def wall_tab?
    current_page?(controller: "projects", action: "wall", id: @project)
  end

  def project_tab_class
    [:show, :files, :edit, :update].each do |action|
      return "active" if current_page?(controller: "projects", action: action, id: @project)
    end

    if ['snippets', 'hooks', 'deploy_keys', 'team_members'].include? controller.controller_name
     "active"
    end
  end

  def branches_tab_class
    if current_page?(branches_project_repository_path(@project)) ||
      controller.controller_name == "protected_branches" ||
      current_page?(project_repository_path(@project))
      'active'
    end
  end
end
