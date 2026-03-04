# frozen_string_literal: true

require 'nokogiri'
require 'asciidoctor/extensions/asciidoctor_kroki/version'
require 'asciidoctor/extensions/asciidoctor_kroki/extension'

module Banzai
  module Filter
    # HTML that replaces all diagrams supported by Kroki with the corresponding img tags.
    # If the source content is large then the hidden attribute is added to the img tag.
    class KrokiFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck
      include Concerns::DiagramService

      MAX_CHARACTER_LIMIT = 2000
      DIAGRAM_FORMAT = 'svg'

      def call
        return doc unless settings.kroki_enabled?

        diagram_formats = ::Gitlab::Kroki.formats(settings)
        diagram_selectors = diagram_formats.map do |diagram_type|
          css_selector_for_code_blocks(lang: diagram_type)
        end.join(', ')

        xpath = Gitlab::Utils::Nokogiri.css_to_xpath(diagram_selectors)

        doc.xpath(xpath).each do |node|
          diagram_type = lang_from_code_block(node)
          next unless diagram_formats.include?(diagram_type)

          diagram_src = node.content.chomp

          img_tag = doc.document.create_element('img')
          img_tag['src'] = self.class.kroki_image_src(diagram_type, diagram_src)

          lazy_load = diagram_src.length > MAX_CHARACTER_LIMIT
          img_tag.set_attribute('hidden', '') if lazy_load
          img_tag.set_attribute('class', 'js-render-kroki')

          img_tag.set_attribute('data-diagram', diagram_type)
          img_tag.set_attribute('data-diagram-src', "data:text/plain;base64,#{Base64.strict_encode64(diagram_src)}")

          node.parent.replace(img_tag)
        end

        doc
      end

      class << self
        def kroki_image_src(diagram_type, diagram_src)
          ::AsciidoctorExtensions::KrokiDiagram.new(diagram_type, DIAGRAM_FORMAT, diagram_src)
            .get_diagram_uri(Gitlab::CurrentSettings.kroki_url)
        end
      end
    end
  end
end
