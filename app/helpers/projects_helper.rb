module ProjectsHelper
  def remove_from_project_team_message(project, user)
    "You are going to remove #{user.name} from #{project.name} project team. Are you sure?"
  end

  def link_to_project project
    link_to project do
      title = content_tag(:span, project.name, class: 'projet-name')

      if project.namespace
        namespace = content_tag(:span, "#{project.namespace.human_name} / ", class: 'namespace-name')
        title = namespace + title
      end

      title
    end
  end

  def link_to_member(project, author, opts = {})
    default_opts = { avatar: true, name: true, size: 16 }
    opts = default_opts.merge(opts)

    return "(deleted)" unless author

    author_html =  ""

    # Build avatar image tag
    author_html << image_tag(avatar_icon(author.try(:email), opts[:size]), width: opts[:size], class: "avatar avatar-inline #{"s#{opts[:size]}" if opts[:size]}", alt:'') if opts[:avatar]

    # Build name span tag
    author_html << content_tag(:span, sanitize(author.name), class: 'author') if opts[:name]

    author_html = author_html.html_safe

    if opts[:name]
      link_to(author_html, user_path(author), class: "author_link").html_safe
    else
      link_to(author_html, user_path(author), class: "author_link has_tooltip", data: { :'original-title' => sanitize(author.name) } ).html_safe
    end
  end

  def project_title project
    if project.group
      content_tag :span do
        link_to(simple_sanitize(project.group.name), group_path(project.group)) + " / " + project.name
      end
    else
      owner = project.namespace.owner
      content_tag :span do
        link_to(simple_sanitize(owner.name), user_path(owner)) + " / " + project.name
      end
    end
  end

  def remove_project_message(project)
    "You are going to remove #{project.name_with_namespace}.\n Removed project CANNOT be restored!\n Are you ABSOLUTELY sure?"
  end

  def project_nav_tabs
    @nav_tabs ||= get_project_nav_tabs(@project, current_user)
  end

  def project_nav_tab?(name)
    project_nav_tabs.include? name
  end

  def selected_label?(label_name)
    params[:label_name].to_s.split(',').include?(label_name)
  end

  def labels_filter_path(label_name)
    label_name =
      if selected_label?(label_name)
        params[:label_name].split(',').reject { |l| l == label_name }.join(',')
      elsif params[:label_name].present?
        "#{params[:label_name]},#{label_name}"
      else
        label_name
      end

    project_filter_path(label_name: label_name)
  end

  def label_filter_class(label_name)
    if selected_label?(label_name)
      'label-filter-item active'
    else
      'label-filter-item light'
    end
  end

  def project_filter_path(options={})
    exist_opts = {
      state: params[:state],
      scope: params[:scope],
      label_name: params[:label_name],
      milestone_id: params[:milestone_id],
      assignee_id: params[:assignee_id],
      sort: params[:sort],
    }

    options = exist_opts.merge(options)

    path = request.path
    path << "?#{options.to_param}"
    path
  end

  def project_active_milestones
    @project.milestones.active.order("due_date, title ASC")
  end

  def project_issues_trackers(current_tracker = nil)
    values = Project.issues_tracker.values.map do |tracker_key|
      if tracker_key.to_sym == :gitlab
        ['GitLab', tracker_key]
      else
        [Gitlab.config.issues_tracker[tracker_key]['title'] || tracker_key, tracker_key]
      end
    end

    options_for_select(values, current_tracker)
  end

  private

  def get_project_nav_tabs(project, current_user)
    nav_tabs = [:home]

    if !project.empty_repo? && can?(current_user, :download_code, project)
      nav_tabs << [:files, :commits, :network, :graphs]
    end

    if project.repo_exists? && project.merge_requests_enabled
      nav_tabs << :merge_requests
    end

    if can?(current_user, :admin_project, project)
      nav_tabs << :settings
    end

    [:issues, :wiki, :wall, :snippets].each do |feature|
      nav_tabs << feature if project.send :"#{feature}_enabled"
    end

    nav_tabs.flatten
  end

  def git_user_name
    if current_user
      current_user.name
    else
      "Your name"
    end
  end

  def git_user_email
    if current_user
      current_user.email
    else
      "your@email.com"
    end
  end

  def repository_size(project = nil)
    "#{(project || @project).repository.size} MB"
  rescue
    # In order to prevent 500 error
    # when application cannot allocate memory
    # to calculate repo size - just show 'Unknown'
    'unknown'
  end

  def project_head_title
    title = @project.name_with_namespace

    title = if current_controller?(:tree)
              "#{@project.path}\/#{@path} at #{@ref} - " + title
            elsif current_controller?(:issues)
              if current_action?(:show)
                "Issue ##{@issue.iid} - #{@issue.title} - " + title
              else
                "Issues - " + title
              end
            elsif current_controller?(:blob)
              "#{@project.path}\/#{@blob.path} at #{@ref} - " + title
            elsif current_controller?(:commits)
              "Commits at #{@ref} - " + title
            elsif current_controller?(:merge_requests)
              if current_action?(:show)
                "Merge request ##{@merge_request.iid} - " + title
              else
                "Merge requests - " + title
              end
            elsif current_controller?(:wikis)
              "Wiki - " + title
            elsif current_controller?(:network)
              "Network graph - " + title
            elsif current_controller?(:graphs)
              "Graphs - " + title
            else
              title
            end

    title
  end

  def default_url_to_repo(project = nil)
    project = project || @project
    current_user ? project.url_to_repo : project.http_url_to_repo
  end

  def default_clone_protocol
    current_user ? "ssh" : "http"
  end

  def project_last_activity(project)
    if project.last_activity_at
      time_ago_with_tooltip(project.last_activity_at, 'bottom', 'last_activity_time_ago')
    else
      "Never"
    end
  end
end
