require 'digest/md5'
module ApplicationHelper

  def gravatar_icon(user_email, size = 40)
    gravatar_host = request.ssl? ? "https://secure.gravatar.com" :  "http://www.gravatar.com"
    "#{gravatar_host}/avatar/#{Digest::MD5.hexdigest(user_email)}?s=#{size}&d=identicon"
  end

  def fixed_mode?
    true
  end

  def body_class(default_class = nil)
    main = content_for(:body_class).blank? ?
      default_class :
      content_for(:body_class)

    [main, "collapsed"].join(" ")
  end

  def commit_name(project, commit)
    if project.commit.id == commit.id
      "master"
    else
      commit.id
    end
  end

  def admin_namespace?
    controller.class.name.split("::").first=="Admin"
  end

  def projects_namespace?
    !current_page?(root_url) &&
      controller.controller_name != "keys" &&
      !admin_namespace?
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
      ["Branch", @project.repo.heads.map(&:name) ],
      [ "Tag", @project.tags ]
    ]

    grouped_options_for_select(options, @ref || @project.default_branch)
  end

  def markdown(text)
    RDiscount.new(text, :autolink, :no_pseudo_protocols, :safelink, :smart, :filter_html).to_html.html_safe
  end

  def search_autocomplete_source
    projects = current_user.projects.map{ |p| { :label => p.name, :url => project_path(p) } }
    default_nav = [
      { :label => "Keys", :url => keys_path },
      { :label => "Projects", :url => projects_path },
      { :label => "Admin", :url => admin_root_path }
    ]

    project_nav = []

    if @project && !@project.new_record?
      project_nav = [
        { :label => "#{@project.code} / Issues", :url => project_issues_path(@project) },
        { :label => "#{@project.code} / Wall", :url => wall_project_path(@project) },
        { :label => "#{@project.code} / Tree", :url => tree_project_ref_path(@project, @project.root_ref) },
        { :label => "#{@project.code} / Commits", :url => project_commits_path(@project) },
        { :label => "#{@project.code} / Team", :url => team_project_path(@project) }
      ]
    end

    [projects, default_nav, project_nav].flatten.to_json
  end

  def project_layout
    @project && !@project.new_record?
  end

  def profile_layout
    controller.controller_name == "dashboard" || current_page?(projects_path) || controller.controller_name == "profile" || controller.controller_name == "keys"
  end

  def help_layout
    controller.controller_name == "help" 
  end

  def ldap_enable?
    Devise.omniauth_providers.include?(:ldap)
  end
end
