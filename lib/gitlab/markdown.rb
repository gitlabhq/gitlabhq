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
      pipeline_type = context[:pipeline] ||= :full
      pipeline_by_type(pipeline_type).call(text, context)
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
      pipeline = pipeline_by_type(:post_process)

      if context[:xhtml]
        pipeline.to_document(html, context).to_html(save_with: Nokogiri::XML::Node::SaveOptions::AS_XHTML)
      else
        pipeline.to_html(html, context)
      end.html_safe
    end

    private

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
      return unless cache_key

      ["markdown", *cache_key, pipeline]
    end

    def self.pipeline_by_type(pipeline_type)
      const_get("#{pipeline_type.to_s.camelize}Pipeline")
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

    autoload :AsciidocPipeline,             'gitlab/markdown/asciidoc_pipeline'
    autoload :AtomPipeline,                 'gitlab/markdown/atom_pipeline'
    autoload :CombinedPipeline,             'gitlab/markdown/combined_pipeline'
    autoload :DescriptionPipeline,          'gitlab/markdown/description_pipeline'
    autoload :EmailPipeline,                'gitlab/markdown/email_pipeline'
    autoload :FullPipeline,                 'gitlab/markdown/full_pipeline'
    autoload :GfmPipeline,                  'gitlab/markdown/gfm_pipeline'
    autoload :NotePipeline,                 'gitlab/markdown/note_pipeline'
    autoload :Pipeline,                     'gitlab/markdown/pipeline'
    autoload :PlainMarkdownPipeline,        'gitlab/markdown/plain_markdown_pipeline'
    autoload :PostProcessPipeline,          'gitlab/markdown/post_process_pipeline'
    autoload :ReferenceExtractionPipeline,  'gitlab/markdown/reference_extraction_pipeline'
    autoload :SingleLinePipeline,           'gitlab/markdown/single_line_pipeline'
  end
end
