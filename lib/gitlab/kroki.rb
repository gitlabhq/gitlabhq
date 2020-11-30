# frozen_string_literal: true

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
    # Diagrams that require a companion container are disabled for now
    DIAGRAMS_FORMATS = ::AsciidoctorExtensions::Kroki::SUPPORTED_DIAGRAM_NAMES
                           .reject { |diagram_type| diagram_type == 'mermaid' || diagram_type == 'bpmn' || BLOCKDIAG_FORMATS.include?(diagram_type) }
    DIAGRAMS_FORMATS_WO_PLANTUML = DIAGRAMS_FORMATS
                                        .reject { |diagram_type| diagram_type == 'plantuml' }

    # Get the list of diagram formats that are currently enabled
    #
    # Returns an Array of diagram formats.
    # If Kroki is not enabled, returns an empty Array.
    def self.formats(current_settings)
      return [] unless current_settings.kroki_enabled

      # If PlantUML is enabled, PlantUML diagrams will be processed by the PlantUML server.
      # In other words, the PlantUML server has precedence over Kroki since both can process PlantUML diagrams.
      if current_settings.plantuml_enabled
        DIAGRAMS_FORMATS_WO_PLANTUML
      else
        DIAGRAMS_FORMATS
      end
    end
  end
end
