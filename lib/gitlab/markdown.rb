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
  #   * JIRA-123 for Jira issues
  #   * !123 for merge requests
  #   * $123 for snippets
  #   * 1c002d for specific commit
  #   * 1c002d...35cfb2 for commit ranges (comparisons)
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

      markdown_context = {
        asset_root:      Gitlab.config.gitlab.url,
        asset_host:      Gitlab::Application.config.asset_host,
        whitelist:       sanitization_whitelist,
        reference_class: html_options[:class],
        only_path:       options[:reference_only_path],
        current_user:    current_user,
        project:         project
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

    # Custom filters for html-pipeline:
    #
    # SanitizationFilter should come first so that all generated reference HTML
    # goes through untouched.
    #
    # See https://gitlab.com/gitlab-org/html-pipeline-gitlab for more filters
    def filters
      [
        HTML::Pipeline::SanitizationFilter,

        Gitlab::Markdown::UserReferenceFilter,
        Gitlab::Markdown::IssueReferenceFilter,
        Gitlab::Markdown::ExternalIssueReferenceFilter,
        Gitlab::Markdown::MergeRequestReferenceFilter,
        Gitlab::Markdown::SnippetReferenceFilter,
        Gitlab::Markdown::CommitRangeReferenceFilter,
        Gitlab::Markdown::CommitReferenceFilter,
        Gitlab::Markdown::LabelReferenceFilter,

        HTML::Pipeline::Gitlab::GitlabEmojiFilter
      ]
    end

    # Customize the SanitizationFilter whitelist
    #
    # - Allow `class` and `id` attributes on all elements
    # - Allow `span` elements
    # - Remove `rel` attributes from `a` elements
    # - Remove `a` nodes with `javascript:` in the `href` attribute
    def sanitization_whitelist
      whitelist = HTML::Pipeline::SanitizationFilter::WHITELIST
      whitelist[:attributes][:all].push('class', 'id')
      whitelist[:elements].push('span')

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

      whitelist
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
