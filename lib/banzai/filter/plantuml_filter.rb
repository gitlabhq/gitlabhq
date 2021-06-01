# frozen_string_literal: true

require "nokogiri"
require "asciidoctor_plantuml/plantuml"

module Banzai
  module Filter
    # HTML that replaces all `code plantuml` tags with PlantUML img tags.
    #
    class PlantumlFilter < HTML::Pipeline::Filter
      CSS   = 'pre > code[lang="plantuml"]'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      def call
        return doc unless settings.plantuml_enabled? && doc.at_xpath(XPATH)

        plantuml_setup

        doc.xpath(XPATH).each do |node|
          img_tag = Nokogiri::HTML::DocumentFragment.parse(
            Asciidoctor::PlantUml::Processor.plantuml_content(node.content, {}))
          node.parent.replace(img_tag)
        end

        doc
      end

      private

      def settings
        Gitlab::CurrentSettings.current_application_settings
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
