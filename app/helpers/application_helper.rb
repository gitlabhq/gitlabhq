# frozen_string_literal: true

require 'digest/md5'
require 'uri'

module ApplicationHelper
  # See https://docs.gitlab.com/ee/development/ee_features.html#code-in-app-views
  # rubocop: disable CodeReuse/ActiveRecord
  def render_if_exists(partial, locals = {})
    render(partial, locals) if partial_exists?(partial)
  end

  def partial_exists?(partial)
    lookup_context.exists?(partial, [], true)
  end

  def template_exists?(template)
    lookup_context.exists?(template, [], false)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # Check if a particular controller is the current one
  #
  # args - One or more controller names to check (using path notation when inside namespaces)
  #
  # Examples
  #
  #   # On TreeController
  #   current_controller?(:tree)           # => true
  #   current_controller?(:commits)        # => false
  #   current_controller?(:commits, :tree) # => true
  #
  #   # On Admin::ApplicationController
  #   current_controller?(:application)         # => true
  #   current_controller?('admin/application')  # => true
  #   current_controller?('gitlab/application') # => false
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
  # rubocop: disable CodeReuse/ActiveRecord
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
  # rubocop: enable CodeReuse/ActiveRecord

  def hexdigest(string)
    Digest::SHA1.hexdigest string
  end

  def simple_sanitize(str)
    sanitize(str, tags: %w(a span))
  end

  def body_data
    {
      page: body_data_page,
      page_type_id: controller.params[:id],
      find_file: find_file_path,
      group: "#{@group&.path}"
    }.merge(project_data)
  end

  def project_data
    return {} unless @project

    {
      project_id: @project.id,
      project: @project.path,
      namespace_id: @project.namespace&.id
    }
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

  # shortcut for gitlab registry config
  def registry_config
    Gitlab.config.registry
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
    css_classes = [short_format ? 'js-short-timeago' : 'js-timeago']
    css_classes << html_class unless html_class.blank?

    element = content_tag :time, l(time, format: "%b %d, %Y"),
      class: css_classes.join(' '),
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

  def static_objects_external_storage_enabled?
    Gitlab::CurrentSettings.static_objects_external_storage_enabled?
  end

  def external_storage_url_or_path(path, project = @project)
    return path unless static_objects_external_storage_enabled?

    uri = URI(Gitlab::CurrentSettings.static_objects_external_storage_url)
    path = URI(path) # `path` could have query parameters, so we need to split query and path apart

    query = Rack::Utils.parse_nested_query(path.query)
    query['token'] = current_user.static_object_token unless project.public?

    uri.path = path.path
    uri.query = query.to_query unless query.empty?

    uri.to_s
  end

  def page_filter_path(options = {})
    without = options.delete(:without)

    options = request.query_parameters.merge(options)

    if without.present?
      without.each do |key|
        options.delete(key)
      end
    end

    "#{request.path}?#{options.compact.to_param}"
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
    class_names << system_message_class
    class_names
  end

  def system_message_class
    class_names = []

    return class_names unless appearance

    class_names << 'with-system-header' if appearance.show_header?
    class_names << 'with-system-footer' if appearance.show_footer?

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

  def client_class_list
    "gl-browser-#{browser.id} gl-platform-#{browser.platform.id}"
  end

  def client_js_flags
    {
      "is#{browser.id.to_s.titlecase}": true,
      "is#{browser.platform.id.to_s.titlecase}": true
    }
  end

  def autocomplete_data_sources(object, noteable_type)
    return {} unless object && noteable_type

    {
      members: members_project_autocomplete_sources_path(object, type: noteable_type, type_id: params[:id]),
      issues: issues_project_autocomplete_sources_path(object),
      mergeRequests: merge_requests_project_autocomplete_sources_path(object),
      labels: labels_project_autocomplete_sources_path(object, type: noteable_type, type_id: params[:id]),
      milestones: milestones_project_autocomplete_sources_path(object),
      commands: commands_project_autocomplete_sources_path(object, type: noteable_type, type_id: params[:id]),
      snippets: snippets_project_autocomplete_sources_path(object)
    }
  end

  def asset_to_string(name)
    app = Rails.application
    if Rails.configuration.assets.compile
      app.assets.find_asset(name).to_s
    else
      controller.view_context.render(file: Rails.root.join('public/assets', app.assets_manifest.assets[name]).to_s)
    end
  end

  private

  def appearance
    ::Appearance.current
  end
end

ApplicationHelper.prepend_if_ee('EE::ApplicationHelper')
