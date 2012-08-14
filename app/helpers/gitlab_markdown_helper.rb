module GitlabMarkdownHelper
  REFERENCE_PATTERN = %r{
    (\W)?              # Prefix (1)
    (                  # Reference (2)
      @([\w\._]+)    | # User name (3)
      [#!$](\d+)     | # Issue/MR/Snippet ID (4)
      [\h]{6,40}       # Commit ID (2)
    )
    (\W)?              # Suffix (5)
  }x.freeze

  def gfm(text, html_options = {})
    return text if text.nil?
    return text if @project.nil?

    # Extract pre blocks
    # from http://github.github.com/github-flavored-markdown/
    extractions = {}
    text.gsub!(%r{<pre>.*?</pre>|<code>.*?</code>}m) do |match|
      md5 = Digest::MD5.hexdigest(match)
      extractions[md5] = match
      "{gfm-extraction-#{md5}}"
    end

    text.gsub!(REFERENCE_PATTERN) do |match|
      vals = {
        prefix:       $1,
        reference:    $2,
        user_name:    $3,
        reference_id: $4,
        suffix:       $5
      }

      if ref_link = reference_link(vals, html_options)
        sprintf('%s%s%s', vals[:prefix], ref_link, vals[:suffix])
      else
        match
      end
    end

    # Insert pre block extractions
    text.gsub!(/\{gfm-extraction-(\h{32})\}/) do
      extractions[$1]
    end

    text.html_safe
  end

  # circumvents nesting links, which will behave bad in browsers
  def link_to_gfm(body, url, html_options = {})
    gfm_body = gfm(body, html_options)

    gfm_body.gsub!(%r{<a.*?>.*?</a>}m) do |match|
      "</a>#{match}#{link_to("", url, html_options)[0..-5]}" # "</a>".length +1
    end

    link_to(gfm_body.html_safe, url, html_options)
  end

  def markdown(text)
    @__renderer ||= Redcarpet::Markdown.new(Redcarpet::Render::GitlabHTML.new(self, filter_html: true, with_toc_data: true), {
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

  private

  def reference_link(vals, html_options)
    # TODO: add popups with additional information
    case vals[:reference]

      # team member: @foo
    when /^@/
      user = @project.users.where(name: vals[:user_name]).first
      member = @project.users_projects.where(user_id: user).first if user
      link_to("@#{user.name}", project_team_member_path(@project, member), html_options.merge(class: "gfm gfm-team_member #{html_options[:class]}")) if member

    # issue: #123
    when /^#/
      # avoid HTML entities
      unless vals[:prefix].try(:end_with?, "&") && vals[:suffix].try(:start_with?, ";")
        issue = @project.issues.where(id: vals[:reference_id]).first
        link_to("##{issue.id}", project_issue_path(@project, issue), html_options.merge(title: "Issue: #{issue.title}", class: "gfm gfm-issue #{html_options[:class]}")) if issue
      end

    # merge request: !123
    when /^!/
      merge_request = @project.merge_requests.where(id: vals[:reference_id]).first
      link_to("!#{merge_request.id}", project_merge_request_path(@project, merge_request), html_options.merge(title: "Merge Request: #{merge_request.title}", class: "gfm gfm-merge_request #{html_options[:class]}")) if merge_request

    # snippet: $123
    when /^\$/
      snippet = @project.snippets.where(id: vals[:reference_id]).first
      link_to("$#{snippet.id}", project_snippet_path(@project, snippet), html_options.merge(title: "Snippet: #{snippet.title}", class: "gfm gfm-snippet #{html_options[:class]}")) if snippet

    # commit: 123456...
    when /^\h/
      commit = @project.commit(vals[:reference])
      link_to(vals[:reference], project_commit_path(@project, id: commit.id), html_options.merge(title: "Commit: #{commit.author_name} - #{CommitDecorator.new(commit).title}", class: "gfm gfm-commit #{html_options[:class]}")) if commit

    end
  end
end
