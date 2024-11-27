# frozen_string_literal: true

require "nokogiri"
require "asciidoctor_plantuml/plantuml"

module Banzai
  module Filter
    # HTML that replaces all `lang plantuml` tags with PlantUML img tags.
    #
    class PlantumlFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck
      include ActionView::Helpers::TagHelper
      include Gitlab::Utils::StrongMemoize

      def call
        return doc unless settings.plantuml_enabled? && doc.at_xpath(lang_tag)
        return doc unless plantuml_url_valid?

        Gitlab::Plantuml.configure

        doc.xpath(lang_tag).each do |node|
          next if node.content.blank?

          image_src = create_image_src('png', node.content)
          img_tag = Nokogiri::HTML::DocumentFragment.parse(content_tag(:img, nil, src: image_src))
          img_tag = img_tag.children.first

          img_tag.add_class('plantuml')
          img_tag.set_attribute('data-diagram', 'plantuml')
          img_tag.set_attribute('data-diagram-src', "data:text/plain;base64,#{Base64.strict_encode64(node.content)}")

          node.parent.replace(img_tag)
        end

        doc
      end

      private

      def lang_tag
        @lang_tag ||= Gitlab::Utils::Nokogiri
          .css_to_xpath('pre[data-canonical-lang="plantuml"] > code, pre > code[data-canonical-lang="plantuml"]').freeze
      end

      def settings
        Gitlab::CurrentSettings.current_application_settings
      end
      strong_memoize_attr :settings

      def create_image_src(format, text)
        Asciidoctor::PlantUml::Processor.gen_url(text, format)
      end

      def plantuml_url_valid?
        ::Gitlab::UrlSanitizer.valid_web?(settings.plantuml_url)
      end
    end
  end
end
