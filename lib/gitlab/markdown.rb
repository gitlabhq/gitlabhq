require 'html/pipeline'

module Gitlab
  # Custom parser for GitLab-flavored Markdown
  #
  # See the files in `lib/gitlab/markdown/` for specific processing information.
  module Markdown
    # Convert a Markdown String into an HTML-safe String of HTML
    #
    # Note that while the returned HTML will have been sanitized of dangerous
    # HTML, it may post a risk of information leakage if it's not also passed
    # through `post_process`.
    #
    # Also note that the returned String is always HTML, not XHTML. Views
    # requiring XHTML, such as Atom feeds, need to call `post_process` on the
    # result, providing the appropriate `pipeline` option.
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

    # Perform post-processing on an HTML String
    #
    # This method is used to perform state-dependent changes to a String of
    # HTML, such as removing references that the current user doesn't have
    # permission to make (`RedactorFilter`).
    #
    # html     - String to process
    # options  - Hash of options to customize output
    #            :pipeline  - Symbol pipeline type
    #            :project   - Project
    #            :user      - User object
    #
    # Returns an HTML-safe String
    def self.post_process(html, options)
      context = {
        project:      options[:project],
        current_user: options[:user]
      }
      doc = post_processor.to_document(html, context)

      if options[:pipeline] == :atom
        doc.to_html(save_with: Nokogiri::XML::Node::SaveOptions::AS_XHTML)
      else
        doc.to_html
      end.html_safe
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
    autoload :RedactorFilter,               'gitlab/markdown/redactor_filter'
    autoload :RelativeLinkFilter,           'gitlab/markdown/relative_link_filter'
    autoload :SanitizationFilter,           'gitlab/markdown/sanitization_filter'
    autoload :SnippetReferenceFilter,       'gitlab/markdown/snippet_reference_filter'
    autoload :SyntaxHighlightFilter,        'gitlab/markdown/syntax_highlight_filter'
    autoload :TableOfContentsFilter,        'gitlab/markdown/table_of_contents_filter'
    autoload :TaskListFilter,               'gitlab/markdown/task_list_filter'
    autoload :UserReferenceFilter,          'gitlab/markdown/user_reference_filter'
    autoload :UploadLinkFilter,             'gitlab/markdown/upload_link_filter'

    # Public: Parse the provided HTML with GitLab-Flavored Markdown
    #
    # html    - HTML String
    # options - A Hash of options used to customize output (default: {})
    #           :no_header_anchors - Disable header anchors in TableOfContentsFilter
    #           :path              - Current path String
    #           :pipeline          - Symbol pipeline type
    #           :project           - Current Project object
    #           :project_wiki      - Current ProjectWiki object
    #           :ref               - Current ref String
    #
    # Returns an HTML-safe String
    def self.gfm(html, options = {})
      return '' unless html.present?

      @pipeline ||= HTML::Pipeline.new(filters)

      context = {
        # SanitizationFilter
        pipeline: options[:pipeline],

        # EmojiFilter
        asset_host: Gitlab::Application.config.asset_host,
        asset_root: Gitlab.config.gitlab.base_url,

        # ReferenceFilter
        only_path: only_path_pipeline?(options[:pipeline]),
        project:   options[:project],

        # RelativeLinkFilter
        project_wiki:   options[:project_wiki],
        ref:            options[:ref],
        requested_path: options[:path],

        # TableOfContentsFilter
        no_header_anchors: options[:no_header_anchors]
      }

      @pipeline.to_html(html, context).html_safe
    end

    private

    # Check if a pipeline enables the `only_path` context option
    #
    # Returns Boolean
    def self.only_path_pipeline?(pipeline)
      case pipeline
      when :atom, :email
        false
      else
        true
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

    def self.renderer
      @markdown ||= begin
        renderer = Redcarpet::Render::HTML.new
        Redcarpet::Markdown.new(renderer, redcarpet_options)
      end
    end

    def self.post_processor
      @post_processor ||= HTML::Pipeline.new([Gitlab::Markdown::RedactorFilter])
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

        Gitlab::Markdown::UploadLinkFilter,
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
