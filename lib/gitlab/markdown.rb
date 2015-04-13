require 'html/pipeline'
require 'html/pipeline/gitlab'

module Gitlab
  # Custom parser for GitLab-flavored Markdown
  #
  # It replaces references in the text with links to the appropriate items in
  # GitLab.
  #
  # Supported reference formats are:
  #   * @foo for team members
  #   * #123 for issues
  #   * #JIRA-123 for Jira issues
  #   * !123 for merge requests
  #   * $123 for snippets
  #   * 123456 for commits
  #   * 123456...7890123 for commit ranges (comparisons)
  #
  # It also parses Emoji codes to insert images. See
  # http://www.emoji-cheat-sheet.com/ for a list of the supported icons.
  #
  # Examples
  #
  #   >> gfm("Hey @david, can you fix this?")
  #   => "Hey <a href="/u/david">@david</a>, can you fix this?"
  #
  #   >> gfm("Commit 35d5f7c closes #1234")
  #   => "Commit <a href="/gitlab/commits/35d5f7c">35d5f7c</a> closes <a href="/gitlab/issues/1234">#1234</a>"
  #
  #   >> gfm(":trollface:")
  #   => "<img alt=\":trollface:\" class=\"emoji\" src=\"/images/trollface.png" title=\":trollface:\" />
  module Markdown
    include IssuesHelper

    attr_reader :options, :html_options

    # Public: Parse the provided text with GitLab-Flavored Markdown
    #
    # text         - the source text
    # project      - the project
    # html_options - extra options for the reference links as given to link_to
    def gfm(text, project = @project, html_options = {})
      gfm_with_options(text, {}, project, html_options)
    end

    # Public: Parse the provided text with GitLab-Flavored Markdown
    #
    # text         - the source text
    # options      - parse_tasks          - render tasks
    #              - xhtml                - output XHTML instead of HTML
    #              - reference_only_path  - Use relative path for reference links
    # project      - the project
    # html_options - extra options for the reference links as given to link_to
    def gfm_with_options(text, options = {}, project = @project, html_options = {})
      return text if text.nil?

      # Duplicate the string so we don't alter the original, then call to_str
      # to cast it back to a String instead of a SafeBuffer. This is required
      # for gsub calls to work as we need them to.
      text = text.dup.to_str

      options.reverse_merge!(
        parse_tasks:          false,
        xhtml:                false,
        reference_only_path:  true
      )

      @options      = options
      @html_options = html_options

      # Extract pre blocks so they are not altered
      # from http://github.github.com/github-flavored-markdown/
      text.gsub!(%r{<pre>.*?</pre>|<code>.*?</code>}m) { |match| extract_piece(match) }
      # Extract links with probably parsable hrefs
      text.gsub!(%r{<a.*?>.*?</a>}m) { |match| extract_piece(match) }
      # Extract images with probably parsable src
      text.gsub!(%r{<img.*?>}m) { |match| extract_piece(match) }

      # TODO: add popups with additional information

      text = parse(text, project)

      # Insert pre block extractions
      text.gsub!(/\{gfm-extraction-(\h{32})\}/) do
        insert_piece($1)
      end

      # Used markdown pipelines in GitLab:
      # GitlabEmojiFilter - performs emoji replacement.
      # SanitizationFilter - remove unsafe HTML tags and attributes
      #
      # see https://gitlab.com/gitlab-org/html-pipeline-gitlab for more filters
      filters = [
        HTML::Pipeline::Gitlab::GitlabEmojiFilter,
        HTML::Pipeline::SanitizationFilter
      ]

      whitelist = HTML::Pipeline::SanitizationFilter::WHITELIST
      whitelist[:attributes][:all].push('class', 'id')
      whitelist[:elements].push('span')

      # Remove the rel attribute that the sanitize gem adds, and remove the
      # href attribute if it contains inline javascript
      fix_anchors = lambda do |env|
        name, node = env[:node_name], env[:node]
        if name == 'a'
          node.remove_attribute('rel')
          if node['href'] && node['href'].match('javascript:')
            node.remove_attribute('href')
          end
        end
      end
      whitelist[:transformers].push(fix_anchors)

      markdown_context = {
              asset_root: Gitlab.config.gitlab.url,
              asset_host: Gitlab::Application.config.asset_host,
              whitelist: whitelist
      }

      markdown_pipeline = HTML::Pipeline::Gitlab.new(filters).pipeline

      result = markdown_pipeline.call(text, markdown_context)

      save_options = 0
      if options[:xhtml]
        save_options |= Nokogiri::XML::Node::SaveOptions::AS_XHTML
      end

      text = result[:output].to_html(save_with: save_options)

      if options[:parse_tasks]
        text = parse_tasks(text)
      end

      text.html_safe
    end

    private

    def extract_piece(text)
      @extractions ||= {}

      md5 = Digest::MD5.hexdigest(text)
      @extractions[md5] = text
      "{gfm-extraction-#{md5}}"
    end

    def insert_piece(id)
      @extractions[id]
    end

    # Private: Parses text for references and emoji
    #
    # text - Text to parse
    #
    # Returns parsed text
    def parse(text, project = @project)
      parse_references(text, project) if project

      text
    end

    NAME_STR = Gitlab::Regex::NAMESPACE_REGEX_STR
    PROJ_STR = "(?<project>#{NAME_STR}/#{NAME_STR})"

    REFERENCE_PATTERN = %r{
      (?<prefix>\W)?                         # Prefix
      (                                      # Reference
         @(?<user>#{NAME_STR})               # User name
        |~(?<label>\d+)                      # Label ID
        |(?<issue>([A-Z\-]+-)\d+)            # JIRA Issue ID
        |#{PROJ_STR}?\#(?<issue>([a-zA-Z\-]+-)?\d+) # Issue ID
        |#{PROJ_STR}?!(?<merge_request>\d+)  # MR ID
        |\$(?<snippet>\d+)                   # Snippet ID
        |(#{PROJ_STR}@)?(?<commit_range>[\h]{6,40}\.{2,3}[\h]{6,40}) # Commit range
        |(#{PROJ_STR}@)?(?<commit>[\h]{6,40}) # Commit ID
        |(?<skip>gfm-extraction-[\h]{6,40})  # Skip gfm extractions. Otherwise will be parsed as commit
      )
      (?<suffix>\W)?                         # Suffix
    }x.freeze

    TYPES = [:user, :issue, :label, :merge_request, :snippet, :commit, :commit_range].freeze

    def parse_references(text, project = @project)
      # parse reference links
      text.gsub!(REFERENCE_PATTERN) do |match|
        type       = TYPES.select{|t| !$~[t].nil?}.first

        actual_project = project
        project_prefix = nil
        project_path = $LAST_MATCH_INFO[:project]
        if project_path
          actual_project = ::Project.find_with_namespace(project_path)
          actual_project = nil unless can?(current_user, :read_project, actual_project)
          project_prefix = project_path
        end

        parse_result($LAST_MATCH_INFO, type,
                     actual_project, project_prefix) || match
      end
    end

    # Called from #parse_references.  Attempts to build a gitlab reference
    # link.  Returns nil if +type+ is nil, if the match string is an HTML
    # entity, if the reference is invalid, or if the matched text includes an
    # invalid project path.
    def parse_result(match_info, type, project, project_prefix)
      prefix = match_info[:prefix]
      suffix = match_info[:suffix]

      return nil if html_entity?(prefix, suffix) || type.nil?
      return nil if project.nil? && !project_prefix.nil?

      identifier = match_info[type]
      ref_link = reference_link(type, identifier, project, project_prefix)

      if ref_link
        "#{prefix}#{ref_link}#{suffix}"
      else
        nil
      end
    end

    # Return true if the +prefix+ and +suffix+ indicate that the matched string
    # is an HTML entity like &amp;
    def html_entity?(prefix, suffix)
      prefix && suffix && prefix[0] == '&' && suffix[-1] == ';'
    end

    # Private: Dispatches to a dedicated processing method based on reference
    #
    # reference  - Object reference ("@1234", "!567", etc.)
    # identifier - Object identifier (Issue ID, SHA hash, etc.)
    #
    # Returns string rendered by the processing method
    def reference_link(type, identifier, project = @project, prefix_text = nil)
      send("reference_#{type}", identifier, project, prefix_text)
    end

    def reference_user(identifier, project = @project, _ = nil)
      link_options = html_options.merge(
          class: "gfm gfm-project_member #{html_options[:class]}"
        )

      if identifier == "all"
        link_to(
          "@all",
          namespace_project_url(project.namespace, project, only_path: options[:reference_only_path]),
          link_options
        )
      elsif namespace = Namespace.find_by(path: identifier)
        url =
          if namespace.is_a?(Group)
            return nil unless can?(current_user, :read_group, namespace)
            group_url(identifier, only_path: options[:reference_only_path])
          else
            user_url(identifier, only_path: options[:reference_only_path])
          end

        link_to("@#{identifier}", url, link_options)
      end
    end

    def reference_label(identifier, project = @project, _ = nil)
      if label = project.labels.find_by(id: identifier)
        link_options = html_options.merge(
          class: "gfm gfm-label #{html_options[:class]}"
        )
        link_to(
          render_colored_label(label),
          namespace_project_issues_path(project.namespace, project, label_name: label.name),
          link_options
        )
      end
    end

    def reference_issue(identifier, project = @project, prefix_text = nil)
      if project.default_issues_tracker?
        if project.issue_exists? identifier
          url = url_for_issue(identifier, project, only_path: options[:reference_only_path])
          title = title_for_issue(identifier, project)
          link_options = html_options.merge(
            title: "Issue: #{title}",
            class: "gfm gfm-issue #{html_options[:class]}"
          )

          link_to("#{prefix_text}##{identifier}", url, link_options)
        end
      else
        if project.external_issue_tracker.present?
          reference_external_issue(identifier, project,
                                   prefix_text)
        end
      end
    end

    def reference_merge_request(identifier, project = @project, prefix_text = nil)
      if merge_request = project.merge_requests.find_by(iid: identifier)
        link_options = html_options.merge(
          title: "Merge Request: #{merge_request.title}",
          class: "gfm gfm-merge_request #{html_options[:class]}"
        )
        url = namespace_project_merge_request_url(project.namespace, project,
                                                  merge_request,
                                                  only_path: options[:reference_only_path])
        link_to("#{prefix_text}!#{identifier}", url, link_options)
      end
    end

    def reference_snippet(identifier, project = @project, _ = nil)
      if snippet = project.snippets.find_by(id: identifier)
        link_options = html_options.merge(
          title: "Snippet: #{snippet.title}",
          class: "gfm gfm-snippet #{html_options[:class]}"
        )
        link_to(
          "$#{identifier}",
          namespace_project_snippet_url(project.namespace, project, snippet,
                                        only_path: options[:reference_only_path]),
          link_options
        )
      end
    end

    def reference_commit(identifier, project = @project, prefix_text = nil)
      if project.valid_repo? && commit = project.repository.commit(identifier)
        link_options = html_options.merge(
          title: commit.link_title,
          class: "gfm gfm-commit #{html_options[:class]}"
        )
        prefix_text = "#{prefix_text}@" if prefix_text
        link_to(
          "#{prefix_text}#{identifier}",
          namespace_project_commit_url( project.namespace, project, commit,
                                        only_path: options[:reference_only_path]),
          link_options
        )
      end
    end

    def reference_commit_range(identifier, project = @project, prefix_text = nil)
      from_id, to_id = identifier.split(/\.{2,3}/, 2)

      inclusive = identifier !~ /\.{3}/
      from_id << "^" if inclusive

      if project.valid_repo? &&
          from = project.repository.commit(from_id) &&
          to = project.repository.commit(to_id)

        link_options = html_options.merge(
          title: "Commits #{from_id} through #{to_id}",
          class: "gfm gfm-commit_range #{html_options[:class]}"
        )
        prefix_text = "#{prefix_text}@" if prefix_text

        link_to(
          "#{prefix_text}#{identifier}",
          namespace_project_compare_url(project.namespace, project,
                                        from: from_id, to: to_id,
                                        only_path: options[:reference_only_path]),
          link_options
        )
      end
    end

    def reference_external_issue(identifier, project = @project, prefix_text = nil)
      url = url_for_issue(identifier, project, only_path: options[:reference_only_path])
      title = project.external_issue_tracker.title

      link_options = html_options.merge(
        title: "Issue in #{title}",
        class: "gfm gfm-issue #{html_options[:class]}"
      )
      link_to("#{prefix_text}##{identifier}", url, link_options)
    end

    # Turn list items that start with "[ ]" into HTML checkbox inputs.
    def parse_tasks(text)
      li_tag = '<li class="task-list-item">'
      unchecked_box = '<input type="checkbox" value="on" disabled />'
      checked_box = unchecked_box.sub(/\/>$/, 'checked="checked" />')

      # Regexp captures don't seem to work when +text+ is an
      # ActiveSupport::SafeBuffer, hence the `String.new`
      String.new(text).gsub(Taskable::TASK_PATTERN_HTML) do
        checked = $LAST_MATCH_INFO[:checked].downcase == 'x'
        p_tag = $LAST_MATCH_INFO[:p_tag]

        if checked
          "#{li_tag}#{p_tag}#{checked_box}"
        else
          "#{li_tag}#{p_tag}#{unchecked_box}"
        end
      end
    end
  end
end
