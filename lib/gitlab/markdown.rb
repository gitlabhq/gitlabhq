module Gitlab
  # Custom parsing for Gitlab-flavored Markdown
  #
  # Examples
  #
  #   >> m = Markdown.new(...)
  #
  #   >> m.parse("Hey @david, can you fix this?")
  #   => "Hey <a href="/gitlab/team_members/1">@david</a>, can you fix this?"
  #
  #   >> m.parse("Commit 35d5f7c closes #1234")
  #   => "Commit <a href="/gitlab/commits/35d5f7c">35d5f7c</a> closes <a href="/gitlab/issues/1234">#1234</a>"
  class Markdown
    include Rails.application.routes.url_helpers
    include ActionView::Helpers

    REFERENCE_PATTERN = %r{
      ([^\w&;])?      # Prefix (1)
      (               # Reference (2)
        @([\w\._]+)   # User name (3)
        |[#!$](\d+)   # Issue/MR/Snippet ID (4)
        |([\h]{6,40}) # Commit ID (5)
      )
      ([^\w&;])?      # Suffix (6)
    }x.freeze

    attr_reader :html_options

    def initialize(project, html_options = {})
      @project      = project
      @html_options = html_options
    end

    def parse(text)
      text.gsub(REFERENCE_PATTERN) do |match|
        prefix     = $1 || ''
        reference  = $2
        identifier = $3 || $4 || $5
        suffix     = $6 || ''

        if ref_link = reference_link(reference, identifier)
          prefix + ref_link + suffix
        else
          match
        end
      end
    end

    private

    # Private: Dispatches to a dedicated processing method based on reference
    #
    # reference  - Object reference ("@1234", "!567", etc.)
    # identifier - Object identifier (Issue ID, SHA hash, etc.)
    #
    # Returns string rendered by the processing method
    def reference_link(reference, identifier)
      case reference
      when /^@/  then reference_user(identifier)
      when /^#/  then reference_issue(identifier)
      when /^!/  then reference_merge_request(identifier)
      when /^\$/ then reference_snippet(identifier)
      when /^\h/ then reference_commit(identifier)
      end
    end

    def reference_user(identifier)
      if user = @project.users.where(name: identifier).first
        member = @project.users_projects.where(user_id: user).first
        link_to("@#{user.name}", project_team_member_path(@project, member), html_options.merge(class: "gfm gfm-team_member #{html_options[:class]}")) if member
      end
    end

    def reference_issue(identifier)
      if issue = @project.issues.where(id: identifier).first
        link_to("##{issue.id}", project_issue_path(@project, issue), html_options.merge(title: "Issue: #{issue.title}", class: "gfm gfm-issue #{html_options[:class]}"))
      end
    end

    def reference_merge_request(identifier)
      if merge_request = @project.merge_requests.where(id: identifier).first
        link_to("!#{merge_request.id}", project_merge_request_path(@project, merge_request), html_options.merge(title: "Merge Request: #{merge_request.title}", class: "gfm gfm-merge_request #{html_options[:class]}"))
      end
    end

    def reference_snippet(identifier)
      if snippet = @project.snippets.where(id: identifier).first
        link_to("$#{snippet.id}", project_snippet_path(@project, snippet), html_options.merge(title: "Snippet: #{snippet.title}", class: "gfm gfm-snippet #{html_options[:class]}"))
      end
    end

    def reference_commit(identifier)
      if commit = @project.commit(identifier)
        link_to(identifier, project_commit_path(@project, id: commit.id), html_options.merge(title: "Commit: #{commit.author_name} - #{CommitDecorator.new(commit).title}", class: "gfm gfm-commit #{html_options[:class]}"))
      end
    end
  end
end
