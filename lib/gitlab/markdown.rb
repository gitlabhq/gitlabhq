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
      Pipeline[context[:pipeline]].call(text, context)
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
      context = Pipeline[context[:pipeline]].transform_context(context)

      pipeline = Pipeline[:post_process]
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

    def self.full_cache_key(cache_key, pipeline_name)
      return unless cache_key
      ["markdown", *cache_key, pipeline_name || :full]
    end

    # Provide autoload paths for filters to prevent a circular dependency error
    autoload :AutolinkFilter,               'gitlab/markdown/filter/autolink_filter'
    autoload :CommitRangeReferenceFilter,   'gitlab/markdown/filter/commit_range_reference_filter'
    autoload :CommitReferenceFilter,        'gitlab/markdown/filter/commit_reference_filter'
    autoload :EmojiFilter,                  'gitlab/markdown/filter/emoji_filter'
    autoload :ExternalIssueReferenceFilter, 'gitlab/markdown/filter/external_issue_reference_filter'
    autoload :ExternalLinkFilter,           'gitlab/markdown/filter/external_link_filter'
    autoload :IssueReferenceFilter,         'gitlab/markdown/filter/issue_reference_filter'
    autoload :LabelReferenceFilter,         'gitlab/markdown/filter/label_reference_filter'
    autoload :MarkdownFilter,               'gitlab/markdown/filter/markdown_filter'
    autoload :MergeRequestReferenceFilter,  'gitlab/markdown/filter/merge_request_reference_filter'
    autoload :RedactorFilter,               'gitlab/markdown/filter/redactor_filter'
    autoload :ReferenceGathererFilter,      'gitlab/markdown/filter/reference_gatherer_filter'
    autoload :RelativeLinkFilter,           'gitlab/markdown/filter/relative_link_filter'
    autoload :SanitizationFilter,           'gitlab/markdown/filter/sanitization_filter'
    autoload :SnippetReferenceFilter,       'gitlab/markdown/filter/snippet_reference_filter'
    autoload :SyntaxHighlightFilter,        'gitlab/markdown/filter/syntax_highlight_filter'
    autoload :TableOfContentsFilter,        'gitlab/markdown/filter/table_of_contents_filter'
    autoload :TaskListFilter,               'gitlab/markdown/filter/task_list_filter'
    autoload :UserReferenceFilter,          'gitlab/markdown/filter/user_reference_filter'
    autoload :UploadLinkFilter,             'gitlab/markdown/filter/upload_link_filter'

    autoload :AsciidocPipeline,             'gitlab/markdown/pipeline/asciidoc_pipeline'
    autoload :AtomPipeline,                 'gitlab/markdown/pipeline/atom_pipeline'
    autoload :DescriptionPipeline,          'gitlab/markdown/pipeline/description_pipeline'
    autoload :EmailPipeline,                'gitlab/markdown/pipeline/email_pipeline'
    autoload :FullPipeline,                 'gitlab/markdown/pipeline/full_pipeline'
    autoload :GfmPipeline,                  'gitlab/markdown/pipeline/gfm_pipeline'
    autoload :NotePipeline,                 'gitlab/markdown/pipeline/note_pipeline'
    autoload :PlainMarkdownPipeline,        'gitlab/markdown/pipeline/plain_markdown_pipeline'
    autoload :PostProcessPipeline,          'gitlab/markdown/pipeline/post_process_pipeline'
    autoload :ReferenceExtractionPipeline,  'gitlab/markdown/pipeline/reference_extraction_pipeline'
    autoload :SingleLinePipeline,           'gitlab/markdown/pipeline/single_line_pipeline'
  end
end
