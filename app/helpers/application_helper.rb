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

  def gfm(text, html_options = {})
    return text if text.nil?

    # Extract pre blocks
    # from http://github.github.com/github-flavored-markdown/
    extractions = {}
    text.gsub!(%r{<pre>.*?</pre>|<code>.*?</code>}m) do |match|
      md5 = Digest::MD5.hexdigest(match)
      extractions[md5] = match
      "{gfm-extraction-#{md5}}"
    end

    # match     1    2 3               4     5            6
    text.gsub!(/(\W)?(@([\w\._]+)|[#!$](\d+)|([\h]{6,40}))(\W)?/) do |match|
      prefix    = $1
      reference = $2
      user_name = $3
      issue_id  = $4
      merge_request_id = $4
      snippet_id = $4
      commit_id = $5
      suffix    = $6

      # TODO: add popups with additional information
      ref_link = case reference

                  # team member: @foo
                  when /^@/
                    user = @project.users.where(:name => user_name).first
                    member = @project.users_projects.where(:user_id => user).first if user
                    link_to("@#{user_name}", project_team_member_path(@project, member), html_options.merge(:class => "gfm gfm-team_member #{html_options[:class]}")) if member

                  # issue: #123
                  when /^#/
                    # avoid HTML entities
                    unless prefix.try(:end_with?, "&") && suffix.try(:start_with?, ";")
                      issue = @project.issues.where(:id => issue_id).first
                      link_to("##{issue_id}", project_issue_path(@project, issue), html_options.merge(:title => "Issue: #{issue.title}", :class => "gfm gfm-issue #{html_options[:class]}")) if issue
                    end

                  # merge request: !123
                  when /^!/
                    merge_request = @project.merge_requests.where(:id => merge_request_id).first
                    link_to("!#{merge_request_id}", project_merge_request_path(@project, merge_request), html_options.merge(:title => "Merge Request: #{merge_request.title}", :class => "gfm gfm-merge_request #{html_options[:class]}")) if merge_request

                  # snippet: $123
                  when /^\$/
                    snippet = @project.snippets.where(:id => snippet_id).first
                    link_to("$#{snippet_id}", project_snippet_path(@project, snippet), html_options.merge(:title => "Snippet: #{snippet.title}", :class => "gfm gfm-snippet #{html_options[:class]}")) if snippet

                  # commit: 123456...
                  when /^\h/
                    commit = @project.commit(commit_id)
                    link_to(commit_id, project_commit_path(@project, :id => commit.id), html_options.merge(:title => "Commit: #{commit.author_name} - #{CommitDecorator.new(commit).title}", :class => "gfm gfm-commit #{html_options[:class]}")) if commit

                  end # case

      ref_link.nil? ? match : "#{prefix}#{ref_link}#{suffix}"
    end # gsub

    # Insert pre block extractions
    text.gsub!(/\{gfm-extraction-(\h{32})\}/) do
      extractions[$1]
    end

    text.html_safe
  end

  def markdown(text)
    @__renderer ||= Redcarpet::Markdown.new(Redcarpet::Render::GitlabHTML.new(self, filter_html: true), {
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
      { :label => "Profile", :url => profile_path },
      { :label => "Keys", :url => keys_path },
      { :label => "Dashboard", :url => root_path },
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
    Gitlab::Theme.css_class_by_id(current_user.try(:theme_id))
  end

  def show_last_push_widget?(event)
    event && 
      event.last_push_to_non_root? &&
      !event.rm_ref? &&
      event.project && 
      event.project.merge_requests_enabled
  end

  def tab_class(tab_key)
    active = case tab_key
             
             # Project Area
             when :wall; wall_tab?
             when :wiki; controller.controller_name == "wikis"
             when :issues; issues_tab?
             when :network; current_page?(:controller => "projects", :action => "graph", :id => @project)
             when :merge_requests; controller.controller_name == "merge_requests"

             # Dashboard Area
             when :help; controller.controller_name == "help"
             when :search; current_page?(search_path)
             when :dash_issues; current_page?(dashboard_issues_path)
             when :dash_mr; current_page?(dashboard_merge_requests_path)
             when :root; current_page?(dashboard_path) || current_page?(root_path)

             # Profile Area
             when :profile;  current_page?(:controller => "profile", :action => :show)
             when :password; current_page?(:controller => "profile", :action => :password)
             when :token;    current_page?(:controller => "profile", :action => :token)
             when :design;   current_page?(:controller => "profile", :action => :design)
             when :ssh_keys; controller.controller_name == "keys"

             # Admin Area
             when :admin_root;     controller.controller_name == "dashboard"
             when :admin_users;    controller.controller_name == 'users'
             when :admin_projects; controller.controller_name == "projects"
             when :admin_emails;   controller.controller_name == 'mailer'
             when :admin_resque;   controller.controller_name == 'resque'
             when :admin_logs;   controller.controller_name == 'logs'

             else
               false
             end
    active ? "current" : nil
  end

  def hexdigest(string)
    Digest::SHA1.hexdigest string
  end
end
