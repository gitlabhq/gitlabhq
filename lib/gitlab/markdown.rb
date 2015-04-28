require 'html/pipeline'

module Gitlab
  # Custom parser for GitLab-flavored Markdown
  #
  # See the files in `lib/gitlab/markdown/` for specific processing information.
  module Markdown
    # Provide autoload paths for filters to prevent a circular dependency error
    autoload :AutolinkFilter,               'gitlab/markdown/autolink_filter'
    autoload :CommitRangeReferenceFilter,   'gitlab/markdown/commit_range_reference_filter'
    autoload :CommitReferenceFilter,        'gitlab/markdown/commit_reference_filter'
    autoload :EmojiFilter,                  'gitlab/markdown/emoji_filter'
    autoload :ExternalIssueReferenceFilter, 'gitlab/markdown/external_issue_reference_filter'
    autoload :IssueReferenceFilter,         'gitlab/markdown/issue_reference_filter'
    autoload :LabelReferenceFilter,         'gitlab/markdown/label_reference_filter'
    autoload :MergeRequestReferenceFilter,  'gitlab/markdown/merge_request_reference_filter'
    autoload :SanitizationFilter,           'gitlab/markdown/sanitization_filter'
    autoload :SnippetReferenceFilter,       'gitlab/markdown/snippet_reference_filter'
    autoload :TableOfContentsFilter,        'gitlab/markdown/table_of_contents_filter'
    autoload :UserReferenceFilter,          'gitlab/markdown/user_reference_filter'

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

      pipeline = HTML::Pipeline.new(filters)

      context = {
        # EmojiFilter
        asset_root: Gitlab.config.gitlab.url,
        asset_host: Gitlab::Application.config.asset_host,

        # TableOfContentsFilter
        no_header_anchors: options[:no_header_anchors],

        # ReferenceFilter
        current_user:    current_user,
        only_path:       options[:reference_only_path],
        project:         project,
        reference_class: html_options[:class]
      }

      result = pipeline.call(text, context)

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

    # Filters used in our pipeline
    #
    # SanitizationFilter should come first so that all generated reference HTML
    # goes through untouched.
    #
    # See https://github.com/jch/html-pipeline#filters for more filters.
    def filters
      [
        Gitlab::Markdown::SanitizationFilter,

        Gitlab::Markdown::EmojiFilter,
        Gitlab::Markdown::TableOfContentsFilter,
        Gitlab::Markdown::AutolinkFilter,

        Gitlab::Markdown::UserReferenceFilter,
        Gitlab::Markdown::IssueReferenceFilter,
        Gitlab::Markdown::ExternalIssueReferenceFilter,
        Gitlab::Markdown::MergeRequestReferenceFilter,
        Gitlab::Markdown::SnippetReferenceFilter,
        Gitlab::Markdown::CommitRangeReferenceFilter,
        Gitlab::Markdown::CommitReferenceFilter,
        Gitlab::Markdown::LabelReferenceFilter
      ]
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
