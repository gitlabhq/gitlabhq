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
    args.any? { |v| v.to_s.downcase == controller.controller_name }
  end

  # Check if a partcular action is the current one
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

  def gravatar_icon(user_email = '', size = nil)
    size = 40 if size.nil? || size <= 0

    if !Gitlab.config.gravatar.enabled || user_email.blank?
      'no_avatar.png'
    else
      gravatar_url = request.ssl? ? Gitlab.config.gravatar.ssl_url : Gitlab.config.gravatar.plain_url
      user_email.strip!
      sprintf gravatar_url, hash: Digest::MD5.hexdigest(user_email.downcase), size: size
    end
  end

  def last_commit(project)
    if project.repo_exists?
      time_ago_in_words(project.repository.commit.committed_date) + " ago"
    else
      "Never"
    end
  rescue
    "Never"
  end

  def grouped_options_refs(destination = :tree)
    repository = @project.repository

    options = [
      ["Branch", repository.branch_names ],
      [ "Tag", repository.tag_names ]
    ]

    # If reference is commit id -
    # we should add it to branch/tag selectbox
    if(@ref && !options.flatten.include?(@ref) &&
       @ref =~ /^[0-9a-zA-Z]{6,52}$/)
      options << ["Commit", [@ref]]
    end

    grouped_options_for_select(options, @ref || @project.default_branch)
  end

  def search_autocomplete_source
    projects = current_user.authorized_projects.map { |p| { label: "project: #{p.name_with_namespace}", url: project_path(p) } }
    groups = current_user.authorized_groups.map { |group| { label: "group: #{group.name}", url: group_path(group) } }
    teams = current_user.authorized_teams.map { |team| { label: "team: #{team.name}", url: team_path(team) } }

    default_nav = [
      { label: "My Profile", url: profile_path },
      { label: "My SSH Keys", url: keys_path },
      { label: "My Dashboard", url: root_path },
      { label: "Admin Section", url: admin_root_path },
    ]

    help_nav = [
      { label: "help: API Help", url: help_api_path },
      { label: "help: Markdown Help", url: help_markdown_path },
      { label: "help: Permissions Help", url: help_permissions_path },
      { label: "help: Public Access Help", url: help_public_access_path },
      { label: "help: Rake Tasks Help", url: help_raketasks_path },
      { label: "help: SSH Keys Help", url: help_ssh_path },
      { label: "help: System Hooks Help", url: help_system_hooks_path },
      { label: "help: Web Hooks Help", url: help_web_hooks_path },
      { label: "help: Workflow Help", url: help_workflow_path },
    ]

    project_nav = []
    if @project && @project.repository && @project.repository.root_ref
      project_nav = [
        { label: "#{@project.name_with_namespace} - Issues",   url: project_issues_path(@project) },
        { label: "#{@project.name_with_namespace} - Commits",  url: project_commits_path(@project, @ref || @project.repository.root_ref) },
        { label: "#{@project.name_with_namespace} - Merge Requests", url: project_merge_requests_path(@project) },
        { label: "#{@project.name_with_namespace} - Milestones", url: project_milestones_path(@project) },
        { label: "#{@project.name_with_namespace} - Snippets", url: project_snippets_path(@project) },
        { label: "#{@project.name_with_namespace} - Team",     url: project_team_index_path(@project) },
        { label: "#{@project.name_with_namespace} - Tree",     url: project_tree_path(@project, @ref || @project.repository.root_ref) },
        { label: "#{@project.name_with_namespace} - Wall",     url: wall_project_path(@project) },
        { label: "#{@project.name_with_namespace} - Wiki",     url: project_wikis_path(@project) },
      ]
    end

    [groups, projects, default_nav, project_nav, help_nav].flatten.to_json
  end

  def emoji_autocomplete_source
    # should be an array of strings
    # so to_s can be called, because it is sufficient and to_json is too slow
    Emoji.names.to_s
  end

  def ldap_enable?
    Devise.omniauth_providers.include?(:ldap)
  end

  def app_theme
    Gitlab::Theme.css_class_by_id(current_user.try(:theme_id))
  end

  def user_color_scheme_class
    current_user.dark_scheme ? :black : :white
  end

  def show_last_push_widget?(event)
    event &&
      event.last_push_to_non_root? &&
      !event.rm_ref? &&
      event.project &&
      event.project.repository &&
      event.project.merge_requests_enabled
  end

  def hexdigest(string)
    Digest::SHA1.hexdigest string
  end

  def project_last_activity project
    activity = project.last_activity
    if activity && activity.created_at
      time_ago_in_words(activity.created_at) + " ago"
    else
      "Never"
    end
  end

  def authbutton(provider, size = 64)
    file_name = "#{provider.to_s.split('_').first}_#{size}.png"
    image_tag("authbuttons/#{file_name}",
              alt: "Sign in with #{provider.to_s.titleize}")
  end

  def image_url(source)
    root_url + path_to_image(source)
  end
  alias_method :url_to_image, :image_url
end
