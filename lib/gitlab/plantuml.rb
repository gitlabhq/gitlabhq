# frozen_string_literal: true

require "asciidoctor_plantuml/plantuml"

module Gitlab
  module Plantuml
    class << self
      def configure
        Asciidoctor::PlantUml.configure do |conf|
          conf.url        = Gitlab::CurrentSettings.plantuml_url
          conf.png_enable = Gitlab::CurrentSettings.plantuml_enabled
          conf.svg_enable = false
          conf.txt_enable = false

          conf
        end
      end
    end
  end
end
