# frozen_string_literal: true

require "nokogiri"
require "asciidoctor_plantuml/plantuml"

module Banzai
  module Filter
    # HTML that replaces all `lang plantuml` tags with PlantUML img tags.
    #
    class PlantumlFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck
      prepend Concerns::DiagramService

      def call
        return doc unless settings.plantuml_enabled?

        doc.xpath(lang_tag).each do |node|
          diagram_src = node.content.chomp
          img_tag = self.class.plantuml_img_tag(diagram_src)

          next if img_tag.nil?

          img_tag.set_attribute('data-diagram', 'plantuml')
          img_tag.set_attribute('data-diagram-src', "data:text/plain;base64,#{Base64.strict_encode64(diagram_src)}")

          node.parent.replace(img_tag)
        end

        doc
      end

      private

      def lang_tag
        @lang_tag ||= Gitlab::Utils::Nokogiri.css_to_xpath(css_selector_for_code_blocks(lang: 'plantuml')).freeze
      end

      class << self
        def plantuml_img_tag(diagram_src)
          Gitlab::Plantuml.configure

          Nokogiri::HTML::DocumentFragment.parse(
            Asciidoctor::PlantUml::Processor.plantuml_content(diagram_src, {})).css('img').first
        end
      end
    end
  end
end
