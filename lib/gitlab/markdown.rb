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
    def self.render(text, context = {})
      context[:pipeline] ||= :full

      cache_key = context.delete(:cache_key)
      cache_key = full_cache_key(cache_key, context[:pipeline])

      if cache_key
        Rails.cache.fetch(cache_key) do
          cacheless_render(text, context)
        end
      else
        cacheless_render(text, context)
      end
    end

    def self.render_result(text, context = {})
      pipeline = context[:pipeline] ||= :full

      html_pipeline = html_pipelines[pipeline]

      transformers = context_transformers[pipeline]
      context = transformers.reduce(context) { |context, transformer| transformer.call(context) }

      html_pipeline.call(text, context)
    end

    # Perform post-processing on an HTML String
    #
    # This method is used to perform state-dependent changes to a String of
    # HTML, such as removing references that the current user doesn't have
    # permission to make (`RedactorFilter`).
    #
    # html     - String to process
    # context  - Hash of options to customize output
    #            :pipeline  - Symbol pipeline type
    #            :project   - Project
    #            :user      - User object
    #
    # Returns an HTML-safe String
    def self.post_process(html, context)
      html_pipeline = html_pipelines[:post_process]

      if context[:xhtml]
        html_pipeline.to_document(html, context).to_html(save_with: Nokogiri::XML::Node::SaveOptions::AS_XHTML)
      else
        html_pipeline.to_html(html, context)
      end.html_safe
    end

    private

    # Provide autoload paths for filters to prevent a circular dependency error
    autoload :AutolinkFilter,               'gitlab/markdown/autolink_filter'
    autoload :CommitRangeReferenceFilter,   'gitlab/markdown/commit_range_reference_filter'
    autoload :CommitReferenceFilter,        'gitlab/markdown/commit_reference_filter'
    autoload :EmojiFilter,                  'gitlab/markdown/emoji_filter'
    autoload :ExternalIssueReferenceFilter, 'gitlab/markdown/external_issue_reference_filter'
    autoload :ExternalLinkFilter,           'gitlab/markdown/external_link_filter'
    autoload :IssueReferenceFilter,         'gitlab/markdown/issue_reference_filter'
    autoload :LabelReferenceFilter,         'gitlab/markdown/label_reference_filter'
    autoload :MarkdownFilter,               'gitlab/markdown/markdown_filter'
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

    def self.gfm_filters
      @gfm_filters ||= [
        Gitlab::Markdown::SyntaxHighlightFilter,
        Gitlab::Markdown::SanitizationFilter,

        Gitlab::Markdown::UploadLinkFilter,
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

    def self.all_filters
      @all_filters ||= {
        plain_markdown: [
          Gitlab::Markdown::MarkdownFilter
        ],
        gfm: gfm_filters,

        full:           [:plain_markdown, :gfm],
        atom:           :full,
        email:          :full,
        description:    :full,
        note:           :full,
        single_line:    :gfm,

        asciidoc: [
          Gitlab::Markdown::RelativeLinkFilter
        ],

        post_process: [
          Gitlab::Markdown::RelativeLinkFilter, 
          Gitlab::Markdown::RedactorFilter
        ],

        reference_extraction: [
          Gitlab::Markdown::ReferenceGathererFilter
        ]
      }
    end

    def self.all_context_transformers
      @all_context_transformers ||= {
        gfm: {
          only_path: true,

          # EmojiFilter
          asset_host: Gitlab::Application.config.asset_host,
          asset_root: Gitlab.config.gitlab.base_url
        },
        full: :gfm,

        atom: [
          :full, 
          { 
            only_path: false, 
            xhtml: true 
          }
        ],
        email: [
          :full,
          { 
            only_path: false
          }
        ],
        note: [
          :full,
          {
            # TableOfContentsFilter
            no_header_anchors: true
          }
        ],
        description: [
          :full,
          { 
            # SanitizationFilter
            inline_sanitization: true
          }
        ],
        single_line: :gfm,

        post_process: {
          post_process: true
        }
      }
    end

    def self.html_filters
      @html_filters ||= Hash.new do |hash, pipeline|
        filters = get_filters(pipeline)
        hash[pipeline] = filters if pipeline.is_a?(Symbol)
        filters
      end
    end

    def self.html_pipelines
      @html_pipelines ||= Hash.new do |hash, pipeline|
        filters = get_filters(pipeline)
        html_pipeline = HTML::Pipeline.new(filters)
        hash[pipeline] = html_pipeline if pipeline.is_a?(Symbol)
        html_pipeline
      end
    end

    def self.context_transformers
      @context_transformers ||= Hash.new do |hash, pipeline|
        transformers = get_context_transformers(pipeline)
        hash[pipeline] = transformers if pipeline.is_a?(Symbol)
        transformers
      end
    end

    def self.get_filters(pipelines)
      Array.wrap(pipelines).flat_map do |pipeline|
        case pipeline
        when Class
          pipeline
        when Symbol
          html_filters[all_filters[pipeline]]
        when Array
          html_filters[pipeline]
        end
      end.compact
    end

    def self.get_context_transformers(pipelines)
      Array.wrap(pipelines).flat_map do |pipeline|
        case pipeline
        when Hash
          ->(context) { context.merge(pipeline) }
        when Proc
          pipeline
        when Symbol
          context_transformers[all_context_transformers[pipeline]]
        when Array
          context_transformers[pipeline]
        end
      end.compact
    end

    def self.cacheless_render(text, context = {})
      result = render_result(text, context)
      output = result[:output]
      if output.respond_to?(:to_html)
        output.to_html
      else
        output.to_s
      end
    end

    def self.full_cache_key(cache_key, pipeline = :full)
      return unless cache_key && pipeline.is_a?(Symbol)

      ["markdown", *cache_key, pipeline]
    end
  end
end
