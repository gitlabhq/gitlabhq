require 'html/pipeline'

module Gitlab
  # Custom parser for GitLab-flavored Markdown
  #
  # See the files in `lib/gitlab/markdown/` for specific processing information.
  module Markdown
    # Convert a Markdown String into an HTML-safe String of HTML
    #
    # markdown - Markdown String
    # context  - Hash of context options passed to our HTML Pipeline
    #
    # Returns an HTML-safe String
    def self.render(markdown, context = {})
      html = renderer.render(markdown)
      html = gfm(html, context)

      html.html_safe
    end

    # Convert a Markdown String into HTML without going through the HTML
    # Pipeline.
    #
    # Note that because the pipeline is skipped, SanitizationFilter is as well.
    # Do not output the result of this method to the user.
    #
    # markdown - Markdown String
    #
    # Returns a String
    def self.render_without_gfm(markdown)
      renderer.render(markdown)
    end

    # Provide autoload paths for filters to prevent a circular dependency error
    autoload :AutolinkFilter,               'gitlab/markdown/autolink_filter'
    autoload :CommitRangeReferenceFilter,   'gitlab/markdown/commit_range_reference_filter'
    autoload :CommitReferenceFilter,        'gitlab/markdown/commit_reference_filter'
    autoload :EmojiFilter,                  'gitlab/markdown/emoji_filter'
    autoload :ExternalIssueReferenceFilter, 'gitlab/markdown/external_issue_reference_filter'
    autoload :ExternalLinkFilter,           'gitlab/markdown/external_link_filter'
    autoload :IssueReferenceFilter,         'gitlab/markdown/issue_reference_filter'
    autoload :LabelReferenceFilter,         'gitlab/markdown/label_reference_filter'
    autoload :MergeRequestReferenceFilter,  'gitlab/markdown/merge_request_reference_filter'
    autoload :RelativeLinkFilter,           'gitlab/markdown/relative_link_filter'
    autoload :SanitizationFilter,           'gitlab/markdown/sanitization_filter'
    autoload :SnippetReferenceFilter,       'gitlab/markdown/snippet_reference_filter'
    autoload :SyntaxHighlightFilter,        'gitlab/markdown/syntax_highlight_filter'
    autoload :TableOfContentsFilter,        'gitlab/markdown/table_of_contents_filter'
    autoload :TaskListFilter,               'gitlab/markdown/task_list_filter'
    autoload :UserReferenceFilter,          'gitlab/markdown/user_reference_filter'

    # Public: Parse the provided text with GitLab-Flavored Markdown
    #
    # text         - the source text
    # options      - A Hash of options used to customize output (default: {}):
    #                :xhtml               - output XHTML instead of HTML
    #                :reference_only_path - Use relative path for reference links
    def self.gfm(text, options = {})
      return text if text.nil?

      # Duplicate the string so we don't alter the original, then call to_str
      # to cast it back to a String instead of a SafeBuffer. This is required
      # for gsub calls to work as we need them to.
      text = text.dup.to_str

      options.reverse_merge!(
        xhtml:                false,
        reference_only_path:  true,
        project:              options[:project],
        current_user:         options[:current_user]
      )

      @pipeline ||= HTML::Pipeline.new(filters)

      context = {
        # SanitizationFilter
        pipeline: options[:pipeline],

        # EmojiFilter
        asset_root: Gitlab.config.gitlab.base_url,
        asset_host: Gitlab::Application.config.asset_host,

        # TableOfContentsFilter
        no_header_anchors: options[:no_header_anchors],

        # ReferenceFilter
        current_user:    options[:current_user],
        only_path:       options[:reference_only_path],
        project:         options[:project],

        # RelativeLinkFilter
        ref:            options[:ref],
        requested_path: options[:path],
        project_wiki:   options[:project_wiki]
      }

      result = @pipeline.call(text, context)

      save_options = 0
      if options[:xhtml]
        save_options |= Nokogiri::XML::Node::SaveOptions::AS_XHTML
      end

      text = result[:output].to_html(save_with: save_options)

      text.html_safe
    end

    private

    def self.renderer
      @markdown ||= begin
        renderer = Redcarpet::Render::HTML.new
        Redcarpet::Markdown.new(renderer, redcarpet_options)
      end
    end

    def self.redcarpet_options
      # https://github.com/vmg/redcarpet#and-its-like-really-simple-to-use
      @redcarpet_options ||= {
        fenced_code_blocks:  true,
        footnotes:           true,
        lax_spacing:         true,
        no_intra_emphasis:   true,
        space_after_headers: true,
        strikethrough:       true,
        superscript:         true,
        tables:              true
      }.freeze
    end

    # Filters used in our pipeline
    #
    # SanitizationFilter should come first so that all generated reference HTML
    # goes through untouched.
    #
    # See https://github.com/jch/html-pipeline#filters for more filters.
    def self.filters
      [
        Gitlab::Markdown::SyntaxHighlightFilter,
        Gitlab::Markdown::SanitizationFilter,

        Gitlab::Markdown::RelativeLinkFilter,
        Gitlab::Markdown::EmojiFilter,
        Gitlab::Markdown::TableOfContentsFilter,
        Gitlab::Markdown::AutolinkFilter,
        Gitlab::Markdown::ExternalLinkFilter,

        Gitlab::Markdown::UserReferenceFilter,
        Gitlab::Markdown::IssueReferenceFilter,
        Gitlab::Markdown::ExternalIssueReferenceFilter,
        Gitlab::Markdown::MergeRequestReferenceFilter,
        Gitlab::Markdown::SnippetReferenceFilter,
        Gitlab::Markdown::CommitRangeReferenceFilter,
        Gitlab::Markdown::CommitReferenceFilter,
        Gitlab::Markdown::LabelReferenceFilter,

        Gitlab::Markdown::TaskListFilter
      ]
    end
  end
end
