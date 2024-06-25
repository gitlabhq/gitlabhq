# frozen_string_literal: true

require "nokogiri"
require "asciidoctor_plantuml/plantuml"

module Banzai
  module Filter
    # HTML that replaces all `lang plantuml` tags with PlantUML img tags.
    #
    class PlantumlFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck

      def call
        return doc unless settings.plantuml_enabled? && doc.at_xpath(lang_tag)

        Gitlab::Plantuml.configure

        doc.xpath(lang_tag).each do |node|
          img_tag = Nokogiri::HTML::DocumentFragment.parse(
            Asciidoctor::PlantUml::Processor.plantuml_content(node.content, {})).css('img').first

          next if img_tag.nil?

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
    end
  end
end
