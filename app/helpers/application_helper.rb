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
      if project_id.respond_to?(:avatar_url)
        project_id
      else
        Project.find_by_full_path(project_id)
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

  # Takes both user and email and returns the avatar_icon by
  # user (preferred) or email.
  def avatar_icon_for(user = nil, email = nil, size = nil, scale = 2, only_path: true)
    if user
      avatar_icon_for_user(user, size, scale, only_path: only_path)
    elsif email
      avatar_icon_for_email(email, size, scale, only_path: only_path)
    else
      default_avatar
    end
  end

  def avatar_icon_for_email(email = nil, size = nil, scale = 2, only_path: true)
    user = User.find_by_any_email(email.try(:downcase))
    if user
      avatar_icon_for_user(user, size, scale, only_path: only_path)
    else
      gravatar_icon(email, size, scale)
    end
  end

  def avatar_icon_for_user(user = nil, size = nil, scale = 2, only_path: true)
    if user
      user.avatar_url(size: size, only_path: only_path) || default_avatar
    else
      gravatar_icon(nil, size, scale)
    end
  end

  def gravatar_icon(user_email = '', size = nil, scale = 2)
    GravatarService.new.execute(user_email, size, scale) ||
      default_avatar
  end

  def default_avatar
    asset_path('no_avatar.png')
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
    return false unless project && !project.empty_repo? && project.feature_available?(:merge_requests, current_user)

    # Skip if user already created appropriate MR
    return false if project.merge_requests.where(source_branch: event.branch_name).opened.any?

    # Skip if user removed branch right after that
    return false unless project.repository.branch_exists?(event.branch_name)

    true
  end

  def hexdigest(string)
    Digest::SHA1.hexdigest string
  end

  def simple_sanitize(str)
    sanitize(str, tags: %w(a span))
  end

  def body_data_page
    [*controller.controller_path.split('/'), controller.action_name].compact.join(':')
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
  def time_ago_with_tooltip(time, placement: 'top', html_class: '', short_format: false)
    css_classes = short_format ? 'js-short-timeago' : 'js-timeago'
    css_classes << " #{html_class}" unless html_class.blank?

    element = content_tag :time, l(time, format: "%b %d, %Y"),
      class: css_classes,
      title: l(time.to_time.in_time_zone, format: :timeago_tooltip),
      datetime: time.to_time.getutc.iso8601,
      data: {
        toggle: 'tooltip',
        placement: placement,
        container: 'body'
      }

    element
  end

  def edited_time_ago_with_tooltip(object, placement: 'top', html_class: 'time_ago', exclude_author: false)
    return unless object.edited?

    content_tag :small, class: 'edited-text' do
      output = content_tag(:span, 'Edited ')
      output << time_ago_with_tooltip(object.last_edited_at, placement: placement, html_class: html_class)

      if !exclude_author && object.last_edited_by
        output << content_tag(:span, ' by ')
        output << link_to_member(object.project, object.last_edited_by, avatar: false, author_class: nil)
      end

      output
    end
  end

  def promo_host
    'about.gitlab.com'
  end

  def promo_url
    'https://' + promo_host
  end

  def support_url
    Gitlab::CurrentSettings.current_application_settings.help_page_support_url.presence || promo_url + '/getting-help/'
  end

  def page_filter_path(options = {})
    without = options.delete(:without)
    add_label = options.delete(:label)

    exist_opts = {
      state: params[:state],
      scope: params[:scope],
      milestone_title: params[:milestone_title],
      assignee_id: params[:assignee_id],
      assignee_username: params[:assignee_username],
      author_id: params[:author_id],
      author_username: params[:author_username],
      search: params[:search],
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

  def page_class
    class_names = []
    class_names << 'issue-boards-page' if current_controller?(:boards)
    class_names << 'with-performance-bar' if performance_bar_enabled?

    class_names
  end

  # Returns active css class when condition returns true
  # otherwise returns nil.
  #
  # Example:
  #   %li{ class: active_when(params[:filter] == '1') }
  def active_when(condition)
    'active' if condition
  end

  def show_callout?(name)
    cookies[name] != 'true'
  end

  def linkedin_url(user)
    name = user.linkedin
    if name =~ %r{\Ahttps?://(www\.)?linkedin\.com/in/}
      name
    else
      "https://www.linkedin.com/in/#{name}"
    end
  end

  def twitter_url(user)
    name = user.twitter
    if name =~ %r{\Ahttps?://(www\.)?twitter\.com/}
      name
    else
      "https://twitter.com/#{name}"
    end
  end

  def collapsed_sidebar?
    cookies["sidebar_collapsed"] == "true"
  end

  def locale_path
    asset_path("locale/#{Gitlab::I18n.locale}/app.js")
  end

  # Overridden in EE
  def read_only_message
    return unless Gitlab::Database.read_only?

    _('You are on a read-only GitLab instance.')
  end
end
