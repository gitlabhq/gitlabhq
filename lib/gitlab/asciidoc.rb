# frozen_string_literal: true

require 'asciidoctor'
require 'asciidoctor-plantuml'
require 'asciidoctor/extensions/asciidoctor_kroki/extension'
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
        'max-include-depth' => MAX_INCLUDE_DEPTH,
        # This feature is disabled because it relies on File#read to read the file.
        # If we want to enable this feature we will need to provide a "GitLab compatible" implementation.
        # This attribute is typically used to share common config (skinparam...) across all PlantUML diagrams.
        # The value can be a path or a URL.
        'kroki-plantuml-include!' => '',
        # This feature is disabled because it relies on the local file system to save diagrams retrieved from the Kroki server.
        'kroki-fetch-diagram!' => ''
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
        ::Gitlab::Kroki.formats(Gitlab::CurrentSettings).each do |name|
          block ::AsciidoctorExtensions::KrokiBlockProcessor, name
        end
      end

      extra_attrs = path_attrs(context[:requested_path])
      asciidoc_opts = { safe: :secure,
                        backend: :gitlab_html5,
                        attributes: DEFAULT_ADOC_ATTRS
                                        .merge(extra_attrs)
                                        .merge({
                                                   # Define the Kroki server URL from the settings.
                                                   # This attribute cannot be overridden from the AsciiDoc document.
                                                   'kroki-server-url' => Gitlab::CurrentSettings.kroki_url
                                               }),
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
