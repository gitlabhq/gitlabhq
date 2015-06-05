require 'asciidoctor'
require 'html/pipeline'

module Gitlab
  # Parser/renderer for the AsciiDoc format that uses Asciidoctor and filters
  # the resulting HTML through HTML pipeline filters.
  module Asciidoc

    # Provide autoload paths for filters to prevent a circular dependency error
    autoload :RelativeLinkFilter, 'gitlab/markdown/relative_link_filter'

    DEFAULT_ADOC_ATTRS = [
      'showtitle', 'idprefix=user-content-', 'idseparator=-', 'env=gitlab',
      'env-gitlab', 'source-highlighter=html-pipeline'
    ].freeze

    # Public: Converts the provided Asciidoc markup into HTML.
    #
    # input         - the source text in Asciidoc format
    # context       - a Hash with the template context:
    #                 :commit
    #                 :project
    #                 :project_wiki
    #                 :requested_path
    #                 :ref
    # asciidoc_opts - a Hash of options to pass to the Asciidoctor converter
    # html_opts     - a Hash of options for HTML output:
    #                 :xhtml - output XHTML instead of HTML
    #
    def self.render(input, context, asciidoc_opts = {}, html_opts = {})
      asciidoc_opts = asciidoc_opts.reverse_merge(
        safe: :secure,
        backend: html_opts[:xhtml] ? :xhtml5 : :html5,
        attributes: []
      )
      asciidoc_opts[:attributes].unshift(*DEFAULT_ADOC_ATTRS)

      html = ::Asciidoctor.convert(input, asciidoc_opts)

      if context[:project]
        result = HTML::Pipeline.new(filters).call(html, context)

        save_opts = html_opts[:xhtml] ?
          Nokogiri::XML::Node::SaveOptions::AS_XHTML : 0

        html = result[:output].to_html(save_with: save_opts)
      end

      html.html_safe
    end

    private

    def self.filters
      [
        Gitlab::Markdown::RelativeLinkFilter
      ]
    end
  end
end
