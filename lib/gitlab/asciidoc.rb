require 'asciidoctor'
require 'asciidoctor/converter/html5'
require "asciidoctor-plantuml"

module Gitlab
  # Parser/renderer for the AsciiDoc format that uses Asciidoctor and filters
  # the resulting HTML through HTML pipeline filters.
  module Asciidoc
    DEFAULT_ADOC_ATTRS = [
      'showtitle', 'idprefix=user-content-', 'idseparator=-', 'env=gitlab',
      'env-gitlab', 'source-highlighter=html-pipeline', 'icons=font',
      'outfilesuffix=.adoc'
    ].freeze

    # Public: Converts the provided Asciidoc markup into HTML.
    #
    # input         - the source text in Asciidoc format
    #
    def self.render(input, context)
      asciidoc_opts = { safe: :secure,
                        backend: :gitlab_html5,
                        attributes: DEFAULT_ADOC_ATTRS }

      context[:pipeline] = :ascii_doc

      plantuml_setup

      html = ::Asciidoctor.convert(input, asciidoc_opts)
      html = Banzai.render(html, context)
      html.html_safe
    end

    def self.plantuml_setup
      Asciidoctor::PlantUml.configure do |conf|
        conf.url = Gitlab::CurrentSettings.plantuml_url
        conf.svg_enable = Gitlab::CurrentSettings.plantuml_enabled
        conf.png_enable = Gitlab::CurrentSettings.plantuml_enabled
        conf.txt_enable = false
      end
    end

    class Html5Converter < Asciidoctor::Converter::Html5Converter
      extend Asciidoctor::Converter::Config

      register_for 'gitlab_html5'

      def stem(node)
        return super unless node.style.to_sym == :latexmath

        %(<pre#{id_attribute(node)} data-math-style="display"><code>#{node.content}</code></pre>)
      end

      def inline_quoted(node)
        return super unless node.type.to_sym == :latexmath

        %(<code#{id_attribute(node)} data-math-style="inline">#{node.text}</code>)
      end

      private

      def id_attribute(node)
        node.id ? %( id="#{node.id}") : nil
      end
    end
  end
end
