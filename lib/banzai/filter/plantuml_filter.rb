require "nokogiri"
require "asciidoctor-plantuml/plantuml"

module Banzai
  module Filter
    # HTML that replaces all `code plantuml` tags with PlantUML img tags.
    #
    class PlantumlFilter < HTML::Pipeline::Filter
      def call
        return doc unless doc.at('pre.plantuml') && settings.plantuml_enabled

        plantuml_setup

        doc.css('pre.plantuml').each do |el|
          img_tag = Nokogiri::HTML::DocumentFragment.parse(
            Asciidoctor::PlantUml::Processor.plantuml_content(el.content, {}))
          el.replace img_tag
        end

        doc
      end

      private

      def settings
        ApplicationSetting.current || ApplicationSetting.create_from_defaults
      end

      def plantuml_setup
        Asciidoctor::PlantUml.configure do |conf|
          conf.url = settings.plantuml_url
          conf.png_enable = settings.plantuml_enabled
          conf.svg_enable = false
          conf.txt_enable = false
        end
      end
    end
  end
end
