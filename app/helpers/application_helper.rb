require 'digest/md5'
module ApplicationHelper

  def gravatar_icon(user_email = '', size = 40)
    return unless user_email
    gravatar_host = request.ssl? ? "https://secure.gravatar.com" :  "http://www.gravatar.com"
    user_email.strip!
    "#{gravatar_host}/avatar/#{Digest::MD5.hexdigest(user_email.downcase)}?s=#{size}&d=identicon"
  end

  def request_protocol
    request.ssl? ? "https" : "http"
  end

  def web_app_url
    "#{request_protocol}://#{GIT_HOST["host"]}/"
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

    # If reference is commit id -
    # we should add it to branch/tag selectbox
    if(@ref && !options.flatten.include?(@ref) &&
       @ref =~ /^[0-9a-zA-Z]{6,52}$/)
      options << ["Commit", [@ref]]
    end

    grouped_options_for_select(options, @ref || @project.default_branch)
  end

  def markdown(text)
    @__renderer ||= Redcarpet::Markdown.new(Redcarpet::Render::GitlabHTML.new(filter_html: true), {
      no_intra_emphasis: true,
      tables: true,
      fenced_code_blocks: true,
      autolink: true,
      strikethrough: true,
      lax_html_blocks: true,
      space_after_headers: true,
      superscript: true
    })

    @__renderer.render(text).html_safe
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
        { :label => "#{@project.name} / Issues", :url => project_issues_path(@project) },
        { :label => "#{@project.name} / Wall", :url => wall_project_path(@project) },
        { :label => "#{@project.name} / Tree", :url => tree_project_ref_path(@project, @project.root_ref) },
        { :label => "#{@project.name} / Commits", :url => project_commits_path(@project) },
        { :label => "#{@project.name} / Team", :url => team_project_path(@project) }
      ]
    end

    [projects, default_nav, project_nav].flatten.to_json
  end

  def ldap_enable?
    Devise.omniauth_providers.include?(:ldap)
  end

  def app_theme
    if current_user && current_user.theme_id == 1
      "ui_basic"
    else
      "ui_mars"
    end
  end

end
