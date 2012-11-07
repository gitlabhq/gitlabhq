require 'digest/md5'

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

  def gravatar_icon(user_email = '', size = 40)
    if Gitlab.config.disable_gravatar? || user_email.blank?
      'no_avatar.png'
    else
      gravatar_prefix = request.ssl? ? "https://secure" : "http://www"
      user_email.strip!
      "#{gravatar_prefix}.gravatar.com/avatar/#{Digest::MD5.hexdigest(user_email.downcase)}?s=#{size}&d=identicon"
    end
  end

  def request_protocol
    request.ssl? ? "https" : "http"
  end

  def web_app_url
    "#{request_protocol}://#{Gitlab.config.web_host}/"
  end

  def last_commit(project)
    if project.repo_exists?
      time_ago_in_words(project.commit.committed_date) + " ago"
    else
      "Never"
    end
  rescue
    "Never"
  end

  def grouped_options_refs(destination = :tree)
    options = [
      ["Branch", @project.branch_names ],
      [ "Tag", @project.tag_names ]
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
    projects = current_user.projects.map{ |p| { label: p.name, url: project_path(p) } }

    default_nav = [
      { label: "My Profile", url: profile_path },
      { label: "My SSH Keys", url: keys_path },
      { label: "My Dashboard", url: root_path },
      { label: "Admin Section", url: admin_root_path },
    ]

    help_nav = [
      { label: "Workflow Help", url: help_workflow_path },
      { label: "Permissions Help", url: help_permissions_path },
      { label: "Web Hooks Help", url: help_web_hooks_path },
      { label: "System Hooks Help", url: help_system_hooks_path },
      { label: "API Help", url: help_api_path },
      { label: "Markdown Help", url: help_markdown_path },
      { label: "SSH Keys Help", url: help_ssh_path },
    ]

    project_nav = []
    if @project && !@project.new_record?
      project_nav = [
        { label: "#{@project.name} Issues",   url: project_issues_path(@project) },
        { label: "#{@project.name} Commits",  url: project_commits_path(@project, @ref || @project.root_ref) },
        { label: "#{@project.name} Merge Requests", url: project_merge_requests_path(@project) },
        { label: "#{@project.name} Milestones", url: project_milestones_path(@project) },
        { label: "#{@project.name} Snippets", url: project_snippets_path(@project) },
        { label: "#{@project.name} Team",     url: project_team_index_path(@project) },
        { label: "#{@project.name} Tree",     url: project_tree_path(@project, @ref || @project.root_ref) },
        { label: "#{@project.name} Wall",     url: wall_project_path(@project) },
        { label: "#{@project.name} Wiki",     url: project_wikis_path(@project) },
      ]
    end

    [projects, default_nav, project_nav, help_nav].flatten.to_json
  end

  def emoji_autocomplete_source
    # should be an array of strings
    # so to_s can be called, because it is sufficient and to_json is too slow
    Emoji.names.to_s
  end

  def ldap_enable?
    Devise.omniauth_providers.include?(:ldap)
  end

  def shibboleth_enable?
    Devise.omniauth_providers.include?(:shibboleth)
  end

  def app_theme
    Gitlab::Theme.css_class_by_id(current_user.try(:theme_id))
  end

  def show_last_push_widget?(event)
    event &&
      event.last_push_to_non_root? &&
      !event.rm_ref? &&
      event.project &&
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
end
