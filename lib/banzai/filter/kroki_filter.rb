# frozen_string_literal: true

require "nokogiri"
require "asciidoctor/extensions/asciidoctor_kroki/extension"

module Banzai
  module Filter
    # HTML that replaces all diagrams supported by Kroki with the corresponding img tags.
    #
    class KrokiFilter < HTML::Pipeline::Filter
      def call
        return doc unless settings.kroki_enabled

        diagram_selectors = ::Gitlab::Kroki.formats(settings)
                                .map { |diagram_type| %(pre[lang="#{diagram_type}"] > code) }
                                .join(', ')

        xpath = Gitlab::Utils::Nokogiri.css_to_xpath(diagram_selectors)
        return doc unless doc.at_xpath(xpath)

        diagram_format = "svg"
        doc.xpath(xpath).each do |node|
          diagram_type = node.parent['lang']
          img_tag = Nokogiri::HTML::DocumentFragment.parse(%(<img src="#{create_image_src(diagram_type, diagram_format, node.content)}"/>))
          img_tag = img_tag.children.first

          unless img_tag.nil?
            img_tag.set_attribute('data-diagram', node.parent['lang'])
            img_tag.set_attribute('data-diagram-src', "data:text/plain;base64,#{Base64.strict_encode64(node.content)}")

            node.parent.replace(img_tag)
          end
        end

        doc
      end

      private

      def create_image_src(type, format, text)
        ::AsciidoctorExtensions::KrokiDiagram.new(type, format, text)
          .get_diagram_uri(settings.kroki_url)
      end

      def settings
        Gitlab::CurrentSettings.current_application_settings
      end
    end
  end
end
