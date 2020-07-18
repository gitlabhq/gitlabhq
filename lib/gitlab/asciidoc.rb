# frozen_string_literal: true

require 'asciidoctor'
require 'asciidoctor-plantuml'
require 'asciidoctor/extensions'
require 'gitlab/asciidoc/html5_converter'
require 'gitlab/asciidoc/mermaid_block_processor'
require 'gitlab/asciidoc/syntax_highlighter/html_pipeline_adapter'

module Gitlab
  # Parser/renderer for the AsciiDoc format that uses Asciidoctor and filters
  # the resulting HTML through HTML pipeline filters.
  module Asciidoc
    MAX_INCLUDE_DEPTH = 5
    MAX_INCLUDES = 32
    DEFAULT_ADOC_ATTRS = {
        'showtitle' => true,
        'sectanchors' => true,
        'idprefix' => 'user-content-',
        'idseparator' => '-',
        'env' => 'gitlab',
        'env-gitlab' => '',
        'source-highlighter' => 'gitlab-html-pipeline',
        'icons' => 'font',
        'outfilesuffix' => '.adoc',
        'max-include-depth' => MAX_INCLUDE_DEPTH
    }.freeze

    def self.path_attrs(path)
      return {} unless path

      {
        # Set an empty docname if the path is a directory
        'docname' => if path[-1] == ::File::SEPARATOR
                       ''
                     else
                       ::File.basename(path, '.*')
                     end
      }
    end

    # Public: Converts the provided Asciidoc markup into HTML.
    #
    # input         - the source text in Asciidoc format
    # context       - :commit, :project, :ref, :requested_path
    #
    def self.render(input, context)
      extensions = proc do
        include_processor ::Gitlab::Asciidoc::IncludeProcessor.new(context)
        block ::Gitlab::Asciidoc::MermaidBlockProcessor
      end

      extra_attrs = path_attrs(context[:requested_path])
      asciidoc_opts = { safe: :secure,
                        backend: :gitlab_html5,
                        attributes: DEFAULT_ADOC_ATTRS.merge(extra_attrs),
                        extensions: extensions }

      context[:pipeline] = :ascii_doc
      context[:max_includes] = [MAX_INCLUDES, context[:max_includes]].compact.min

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
  end
end
