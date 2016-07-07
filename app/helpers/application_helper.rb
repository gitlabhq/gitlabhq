require 'digest/md5'
require 'uri'

module ApplicationHelper
  # Check if a particular controller is the current one
  #
  # args - One or more controller names to check
  #
  # Examples
  #
  #   # On TreeController
  #   current_controller?(:tree)           # => true
  #   current_controller?(:commits)        # => false
  #   current_controller?(:commits, :tree) # => true
  def current_controller?(*args)
    args.any? do |v|
      v.to_s.downcase == controller.controller_name || v.to_s.downcase == controller.controller_path
    end
  end

  # Check if a particular action is the current one
  #
  # args - One or more action names to check
  #
  # Examples
  #
  #   # On Projects#new
  #   current_action?(:new)           # => true
  #   current_action?(:create)        # => false
  #   current_action?(:new, :create)  # => true
  def current_action?(*args)
    args.any? { |v| v.to_s.downcase == action_name }
  end

  def project_icon(project_id, options = {})
    project =
      if project_id.is_a?(Project)
        project_id
      else
        Project.find_with_namespace(project_id)
      end

    if project.avatar_url
      image_tag project.avatar_url, options
    else # generated icon
      project_identicon(project, options)
    end
  end

  def project_identicon(project, options = {})
    allowed_colors = {
      red: 'FFEBEE',
      purple: 'F3E5F5',
      indigo: 'E8EAF6',
      blue: 'E3F2FD',
      teal: 'E0F2F1',
      orange: 'FBE9E7',
      gray: 'EEEEEE'
    }

    options[:class] ||= ''
    options[:class] << ' identicon'
    bg_key = project.id % 7
    style = "background-color: ##{allowed_colors.values[bg_key]}; color: #555"

    content_tag(:div, class: options[:class], style: style) do
      project.name[0, 1].upcase
    end
  end

  def avatar_icon(user_or_email = nil, size = nil, scale = 2)
    if user_or_email.is_a?(User)
      user = user_or_email
    else
      user = User.find_by_any_email(user_or_email.try(:downcase))
    end

    if user
      user.avatar_url(size) || default_avatar
    else
      gravatar_icon(user_or_email, size, scale)
    end
  end

  def gravatar_icon(user_email = '', size = nil, scale = 2)
    GravatarService.new.execute(user_email, size, scale) ||
      default_avatar
  end

  def default_avatar
    'no_avatar.png'
  end

  def last_commit(project)
    if project.repo_exists?
      time_ago_with_tooltip(project.repository.commit.committed_date)
    else
      'Never'
    end
  rescue
    'Never'
  end

  # Define whenever show last push event
  # with suggestion to create MR
  def show_last_push_widget?(event)
    # Skip if event is not about added or modified non-master branch
    return false unless event && event.last_push_to_non_root? && !event.rm_ref?

    project = event.project

    # Skip if project repo is empty or MR disabled
    return false unless project && !project.empty_repo? && project.merge_requests_enabled

    # Skip if user already created appropriate MR
    return false if project.merge_requests.where(source_branch: event.branch_name).opened.any?

    # Skip if user removed branch right after that
    return false unless project.repository.branch_exists?(event.branch_name)

    # Skip if this was a mirror update
    return false if project.mirror? && project.repository.up_to_date_with_upstream?(event.branch_name)

    true
  end

  def hexdigest(string)
    Digest::SHA1.hexdigest string
  end

  def simple_sanitize(str)
    sanitize(str, tags: %w(a span))
  end

  def body_data_page
    path = controller.controller_path.split('/')
    namespace = path.first if path.second

    [namespace, controller.controller_name, controller.action_name].compact.join(':')
  end

  # shortcut for gitlab config
  def gitlab_config
    Gitlab.config.gitlab
  end

  # shortcut for gitlab extra config
  def extra_config
    Gitlab.config.extra
  end

  # Render a `time` element with Javascript-based relative date and tooltip
  #
  # time       - Time object
  # placement  - Tooltip placement String (default: "top")
  # html_class - Custom class for `time` element (default: "time_ago")
  # skip_js    - When true, exclude the `script` tag (default: false)
  #
  # By default also includes a `script` element with Javascript necessary to
  # initialize the `timeago` jQuery extension. If this method is called many
  # times, for example rendering hundreds of commits, it's advisable to disable
  # this behavior using the `skip_js` argument and re-initializing `timeago`
  # manually once all of the elements have been rendered.
  #
  # A `js-timeago` class is always added to the element, even when a custom
  # `html_class` argument is provided.
  #
  # Returns an HTML-safe String
  def time_ago_with_tooltip(time, placement: 'top', html_class: 'time_ago', skip_js: false)
    element = content_tag :time, time.to_s,
      class: "#{html_class} js-timeago #{"js-timeago-pending" unless skip_js}",
      datetime: time.to_time.getutc.iso8601,
      title: time.to_time.in_time_zone.to_s(:medium),
      data: { toggle: 'tooltip', placement: placement, container: 'body' }

    unless skip_js
      element << javascript_tag(
        "$('.js-timeago-pending').removeClass('js-timeago-pending').timeago()"
      )
    end

    element
  end

  def edited_time_ago_with_tooltip(object, placement: 'top', html_class: 'time_ago', include_author: false)
    return if object.updated_at == object.created_at

    content_tag :small, class: "edited-text" do
      output = content_tag(:span, "Edited ")
      output << time_ago_with_tooltip(object.updated_at, placement: placement, html_class: html_class)

      if include_author && object.updated_by && object.updated_by != object.author
        output << content_tag(:span, " by ")
        output << link_to_member(object.project, object.updated_by, avatar: false, author_class: nil)
      end

      output
    end
  end

  def render_markup(file_name, file_content)
    if gitlab_markdown?(file_name)
      Hamlit::RailsHelpers.preserve(markdown(file_content))
    elsif asciidoc?(file_name)
      asciidoc(file_content)
    elsif plain?(file_name)
      content_tag :pre, class: 'plain-readme' do
        file_content
      end
    else
      other_markup(file_name, file_content)
    end
  rescue RuntimeError
    simple_format(file_content)
  end

  def plain?(filename)
    Gitlab::MarkupHelper.plain?(filename)
  end

  def markup?(filename)
    Gitlab::MarkupHelper.markup?(filename)
  end

  def gitlab_markdown?(filename)
    Gitlab::MarkupHelper.gitlab_markdown?(filename)
  end

  def asciidoc?(filename)
    Gitlab::MarkupHelper.asciidoc?(filename)
  end

  def promo_host
    'about.gitlab.com'
  end

  def promo_url
    'https://' + promo_host
  end

  def page_filter_path(options = {})
    without = options.delete(:without)
    add_label = options.delete(:label)

    exist_opts = {
      state: params[:state],
      scope: params[:scope],
      milestone_title: params[:milestone_title],
      assignee_id: params[:assignee_id],
      author_id: params[:author_id],
      sort: params[:sort],
      issue_search: params[:issue_search],
      label_name: params[:label_name]
    }

    options = exist_opts.merge(options)

    if without.present?
      without.each do |key|
        options.delete(key)
      end
    end

    params = options.compact

    params.delete(:label_name) unless add_label

    "#{request.path}?#{params.to_param}"
  end

  def outdated_browser?
    browser.ie? && browser.version.to_i < 10
  end

  def path_to_key(key, admin = false)
    if admin
      admin_user_key_path(@user, key)
    else
      profile_key_path(key)
    end
  end

  def state_filters_text_for(entity, project)
    titles = {
      opened: "Open"
    }

    entity_title = titles[entity] || entity.to_s.humanize

    count =
      if project.nil?
        nil
      elsif current_controller?(:issues)
        project.issues.visible_to_user(current_user).send(entity).count
      elsif current_controller?(:merge_requests)
        project.merge_requests.send(entity).count
      end

    html = content_tag :span, entity_title

    if count.present?
      html += " "
      html += content_tag :span, number_with_delimiter(count), class: 'badge'
    end

    html.html_safe
  end

  def truncate_first_line(message, length = 50)
    truncate(message.each_line.first.chomp, length: length) if message
  end

  # While similarly named to Rails's `link_to_if`, this method behaves quite differently.
  # If `condition` is truthy, a link will be returned with the result of the block
  # as its body. If `condition` is falsy, only the result of the block will be returned.
  def conditional_link_to(condition, options, html_options = {}, &block)
    if condition
      link_to options, html_options, &block
    else
      capture(&block)
    end
  end
end
