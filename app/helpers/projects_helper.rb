module ProjectsHelper
  def link_to_project(project)
    link_to [project.namespace.becomes(Namespace), project], title: h(project.name) do
      title = content_tag(:span, project.name, class: 'project-name')

      if project.namespace
        namespace = content_tag(:span, "#{project.namespace.human_name} / ", class: 'namespace-name')
        title = namespace + title
      end

      title
    end
  end

  def link_to_member_avatar(author, opts = {})
    default_opts = { avatar: true, name: true, size: 16, author_class: 'author', title: ":name" }
    opts = default_opts.merge(opts)
    image_tag(avatar_icon(author, opts[:size]), width: opts[:size], class: "avatar avatar-inline #{"s#{opts[:size]}" if opts[:size]}", alt: '') if opts[:avatar]
  end

  def link_to_member(project, author, opts = {}, &block)
    default_opts = { avatar: true, name: true, size: 16, author_class: 'author', title: ":name", tooltip: false }
    opts = default_opts.merge(opts)

    return "(deleted)" unless author

    author_html =  ""

    # Build avatar image tag
    author_html << image_tag(avatar_icon(author, opts[:size]), width: opts[:size], class: "avatar avatar-inline #{"s#{opts[:size]}" if opts[:size]}", alt: '') if opts[:avatar]

    # Build name span tag
    if opts[:by_username]
      author_html << content_tag(:span, sanitize("@#{author.username}"), class: opts[:author_class]) if opts[:name]
    else
      tooltip_data = { placement: 'top' }
      author_html << content_tag(:span, sanitize(author.name), class: [opts[:author_class], ('has-tooltip' if opts[:tooltip])], title: (author.to_reference if opts[:tooltip]), data: (tooltip_data if opts[:tooltip])) if opts[:name]
    end

    author_html << capture(&block) if block

    author_html = author_html.html_safe

    if opts[:name]
      link_to(author_html, user_path(author), class: "author_link #{"#{opts[:extra_class]}" if opts[:extra_class]} #{"#{opts[:mobile_classes]}" if opts[:mobile_classes]}").html_safe
    else
      title = opts[:title].sub(":name", sanitize(author.name))
      link_to(author_html, user_path(author), class: "author_link has-tooltip", title: title, data: { container: 'body' } ).html_safe
    end
  end

  def project_title(project, name = nil, url = nil)
    namespace_link =
      if project.group
        link_to(simple_sanitize(project.group.name), group_path(project.group))
      else
        owner = project.namespace.owner
        link_to(simple_sanitize(owner.name), user_path(owner))
      end

    project_link = link_to simple_sanitize(project.name), project_path(project), { class: "project-item-select-holder" }

    if current_user
      project_link << icon("chevron-down", class: "dropdown-toggle-caret js-projects-dropdown-toggle", aria: { label: "Toggle switch project dropdown" }, data: { target: ".js-dropdown-menu-projects", toggle: "dropdown" })
    end

    full_title = "#{namespace_link} / #{project_link}".html_safe
    full_title << ' &middot; '.html_safe << link_to(simple_sanitize(name), url) if name

    full_title
  end

  def remove_project_message(project)
    "You are going to remove #{project.name_with_namespace}.\n Removed project CANNOT be restored!\n Are you ABSOLUTELY sure?"
  end

  def transfer_project_message(project)
    "You are going to transfer #{project.name_with_namespace} to another owner. Are you ABSOLUTELY sure?"
  end

  def remove_fork_project_message(project)
    "You are going to remove the fork relationship to source project #{@project.forked_from_project.name_with_namespace}.  Are you ABSOLUTELY sure?"
  end

  def project_nav_tabs
    @nav_tabs ||= get_project_nav_tabs(@project, current_user)
  end

  def project_nav_tab?(name)
    project_nav_tabs.include? name
  end

  def project_for_deploy_key(deploy_key)
    if deploy_key.projects.include?(@project)
      @project
    else
      deploy_key.projects.find { |project| can?(current_user, :read_project, project) }
    end
  end

  def can_change_visibility_level?(project, current_user)
    return false unless can?(current_user, :change_visibility_level, project)

    if project.forked?
      project.forked_from_project.visibility_level > Gitlab::VisibilityLevel::PRIVATE
    else
      true
    end
  end

  def license_short_name(project)
    return 'LICENSE' if project.repository.license_key.nil?

    license = Licensee::License.new(project.repository.license_key)

    license.nickname || license.name
  end

  private

  def get_project_nav_tabs(project, current_user)
    nav_tabs = [:home]

    if !project.empty_repo? && can?(current_user, :download_code, project)
      nav_tabs << [:files, :commits, :network, :graphs, :forks]
    end

    if project.repo_exists? && can?(current_user, :read_merge_request, project)
      nav_tabs << :merge_requests
    end

    if can?(current_user, :read_pipeline, project)
      nav_tabs << :pipelines
    end

    if can?(current_user, :read_build, project)
      nav_tabs << :builds
    end

    if Gitlab.config.registry.enabled && can?(current_user, :read_container_image, project)
      nav_tabs << :container_registry
    end

    if can?(current_user, :read_environment, project)
      nav_tabs << :environments
    end

    if can?(current_user, :admin_project, project)
      nav_tabs << :settings
    end

    if can?(current_user, :read_project_member, project)
      nav_tabs << :team
    end

    if can?(current_user, :read_issue, project)
      nav_tabs << :issues
    end

    if can?(current_user, :read_wiki, project)
      nav_tabs << :wiki
    end

    if can?(current_user, :read_project_snippet, project)
      nav_tabs << :snippets
    end

    if can?(current_user, :read_label, project)
      nav_tabs << :labels
    end

    if can?(current_user, :read_milestone, project)
      nav_tabs << :milestones
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

  def repository_size(project = @project)
    size_in_bytes = project.repository_size * 1.megabyte
    number_to_human_size(size_in_bytes, delimiter: ',', precision: 2)
  end

  def default_url_to_repo(project = @project)
    case default_clone_protocol
    when 'krb5'
      project.kerberos_url_to_repo
    when 'ssh'
      project.ssh_url_to_repo
    else
      project.http_url_to_repo
    end
  end

  def default_clone_protocol
    if allowed_protocols_present?
      enabled_protocol
    elsif alternative_kerberos_url? && current_user
      "krb5"
    else
      if !current_user || current_user.require_ssh_key?
        gitlab_config.protocol
      else
        'ssh'
      end
    end
  end

  # Given the current GitLab configuration, check whether the GitLab URL for Kerberos is going to be different than the HTTP URL
  def alternative_kerberos_url?
    Gitlab.config.alternative_gitlab_kerberos_url?
  end

  def project_last_activity(project)
    if project.last_activity_at
      time_ago_with_tooltip(project.last_activity_at, placement: 'bottom', html_class: 'last_activity_time_ago')
    else
      "Never"
    end
  end

  def add_special_file_path(project, file_name:, commit_message: nil)
    namespace_project_new_blob_path(
      project.namespace,
      project,
      project.default_branch || 'master',
      file_name:      file_name,
      commit_message: commit_message || "Add #{file_name.downcase}"
    )
  end

  def add_koding_stack_path(project)
    namespace_project_new_blob_path(
      project.namespace,
      project,
      project.default_branch || 'master',
      file_name:      '.koding.yml',
      commit_message: "Add Koding stack script",
      content: <<-CONTENT.strip_heredoc
        provider:
          aws:
            access_key: '${var.aws_access_key}'
            secret_key: '${var.aws_secret_key}'
        resource:
          aws_instance:
            #{project.path}-vm:
              instance_type: t2.nano
              user_data: |-

                # Created by GitLab UI for :>

                echo _KD_NOTIFY_@Installing Base packages...@

                apt-get update -y
                apt-get install git -y

                echo _KD_NOTIFY_@Cloning #{project.name}...@

                export KODING_USER=${var.koding_user_username}
                export REPO_URL=#{root_url}${var.koding_queryString_repo}.git
                export BRANCH=${var.koding_queryString_branch}

                sudo -i -u $KODING_USER git clone $REPO_URL -b $BRANCH

                echo _KD_NOTIFY_@#{project.name} cloned.@
      CONTENT
    )
  end

  def koding_project_url(project = nil, branch = nil, sha = nil)
    if project
      import_path = "/Home/Stacks/import"

      repo = project.path_with_namespace
      branch ||= project.default_branch
      sha ||= project.commit.short_id

      path = "#{import_path}?repo=#{repo}&branch=#{branch}&sha=#{sha}"

      return URI.join(current_application_settings.koding_url, path).to_s
    end

    current_application_settings.koding_url
  end

  def contribution_guide_path(project)
    if project && contribution_guide = project.repository.contribution_guide
      namespace_project_blob_path(
        project.namespace,
        project,
        tree_join(project.default_branch,
                  contribution_guide.name)
      )
    end
  end

  def readme_path(project)
    filename_path(project, :readme)
  end

  def changelog_path(project)
    filename_path(project, :changelog)
  end

  def license_path(project)
    filename_path(project, :license_blob)
  end

  def version_path(project)
    filename_path(project, :version)
  end

  def ci_configuration_path(project)
    filename_path(project, :gitlab_ci_yml)
  end

  def project_wiki_path_with_version(proj, page, version, is_newest)
    url_params = is_newest ? {} : { version_id: version }
    namespace_project_wiki_path(proj.namespace, proj, page, url_params)
  end

  def project_status_css_class(status)
    case status
    when "started"
      "active"
    when "failed"
      "danger"
    when "finished"
      "success"
    end
  end

  def membership_locked?
    if @project.group && @project.group.membership_lock
      true
    else
      false
    end
  end

  def new_readme_path
    ref = @repository.root_ref if @repository
    ref ||= 'master'

    namespace_project_new_blob_path(@project.namespace, @project, tree_join(ref), file_name: 'README.md')
  end

  def new_license_path
    ref = @repository.root_ref if @repository
    ref ||= 'master'

    namespace_project_new_blob_path(@project.namespace, @project, tree_join(ref), file_name: 'LICENSE')
  end

  def last_push_event
    return unless current_user

    if fork = current_user.fork_of(@project)
      current_user.recent_push(fork.id)
    else
      current_user.recent_push(@project.id)
    end
  end

  def readme_cache_key
    sha = @project.commit.try(:sha) || 'nil'
    [@project.path_with_namespace, sha, "readme"].join('-')
  end

  def round_commit_count(project)
    count = project.commit_count

    if count > 10000
      '10000+'
    elsif count > 5000
      '5000+'
    elsif count > 1000
      '1000+'
    else
      count
    end
  end

  def current_ref
    @ref || @repository.try(:root_ref)
  end

  def filename_path(project, filename)
    if project && blob = project.repository.send(filename)
      namespace_project_blob_path(
        project.namespace,
        project,
        tree_join(project.default_branch, blob.name)
      )
    end
  end

  def sanitize_repo_path(project, message)
    return '' unless message.present?

    message.strip.gsub(project.repository_storage_path.chomp('/'), "[REPOS PATH]")
  end
end
