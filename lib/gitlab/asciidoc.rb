require 'asciidoctor'

module Gitlab
  # Parser/renderer for the AsciiDoc format that uses Asciidoctor and filters
  # the resulting HTML through HTML pipeline filters.
  module Asciidoc

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
    #
    def self.render(input, context, asciidoc_opts = {})
      asciidoc_opts.reverse_merge!(
        safe: :secure,
        backend: :html5,
        attributes: []
      )
      asciidoc_opts[:attributes].unshift(*DEFAULT_ADOC_ATTRS)

      html = ::Asciidoctor.convert(input, asciidoc_opts)

      html = Banzai.post_process(html, context)

      html.html_safe
    end
  end
end
