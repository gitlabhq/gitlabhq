# frozen_string_literal: true

require 'asciidoctor/extensions/asciidoctor_kroki/version'
require 'asciidoctor/extensions/asciidoctor_kroki/extension'

module Gitlab
  # Helper methods for Kroki
  module Kroki
    BLOCKDIAG_FORMATS = %w[
      blockdiag
      seqdiag
      actdiag
      nwdiag
      packetdiag
      rackdiag
    ].freeze

    # We used to explicitly remove 'mermaid' from this list, but now we allow Kroki
    # to preferentially render them, *if* the administrator has explicitly enabled it
    # --- Mermaid requires a companion server for Kroki.
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/498764.
    DIAGRAMS_FORMATS = ::AsciidoctorExtensions::Kroki::SUPPORTED_DIAGRAM_NAMES.dup.freeze
    DIAGRAMS_FORMATS_WO_PLANTUML = (DIAGRAMS_FORMATS - %w[plantuml]).freeze

    # Get the list of diagram formats that are currently enabled
    #
    # Returns an Array of diagram formats.
    # If Kroki is not enabled, returns an empty Array.
    def self.formats(current_settings)
      return [] unless current_settings.kroki_enabled

      # If PlantUML is enabled, PlantUML diagrams will be processed by the PlantUML server.
      # In other words, the PlantUML server has precedence over Kroki since both can process PlantUML diagrams.
      diagram_formats = if current_settings.plantuml_enabled
                          DIAGRAMS_FORMATS_WO_PLANTUML
                        else
                          DIAGRAMS_FORMATS
                        end

      # Diagrams that require a companion container must be explicitly enabled from the settings
      diagram_formats.select do |diagram_type|
        current_settings.kroki_format_supported?(diagram_type)
      end
    end
  end
end
