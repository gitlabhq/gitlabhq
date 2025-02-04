# frozen_string_literal: true

require "asciidoctor_plantuml/plantuml"

module BlobViewer
  class Graph < Base
    include Rich
    include ServerSide

    INTERNAL_EXTENSIONS = %w[mermaid].freeze
    PLANTUML_EXTENSIONS = %w[plantuml pu puml iuml].freeze
    KROKI_EXTENSIONS = %w[d2 dot gv noml plantuml pu puml iuml vg vl].freeze

    self.partial_name = 'graph'
    self.extensions = INTERNAL_EXTENSIONS + PLANTUML_EXTENSIONS + KROKI_EXTENSIONS
    self.binary = false
    self.switcher_icon = 'doc-image'
    self.switcher_title = 'image'

    def self.can_render?(blob, verify_binary: true)
      # most blob views will not be graph files and the local can_render checks are a bit expensive
      return false unless super

      settings = Gitlab::CurrentSettings.current_application_settings
      return true if INTERNAL_EXTENSIONS&.include?(blob.extension)
      return true if settings.plantuml_enabled? && PLANTUML_EXTENSIONS&.include?(blob.extension)
      return true if settings.kroki_enabled? && ::Gitlab::Kroki.formats(settings).include?(graph_format(blob))

      false
    end

    def self.graph_format(blob)
      case blob.extension
      # included formats
      when *%w[mermaid]
        'mermaid'
      # kroki formats
      when *%w[d2]
        'd2'
      when *%w[dot gv]
        'graphviz'
      when *%w[noml]
        'nomnoml'
      when *%w[vg]
        'vega'
      when *%w[vl]
        'vegalite'
      # kroki/plantuml formats
      when *%w[plantuml pu puml iuml]
        'plantuml'
      end
    end

    def banzai_render_context
      {}.tap do |h|
        h[:cache_key] = ['blob', blob.id, 'commit', blob.commit_id]
      end
    end
  end
end
