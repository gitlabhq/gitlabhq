# frozen_string_literal: true

module Banzai
  module Filter
    # HTML filter that renders `color` followed by a color "chip".
    #
    class ColorFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck

      COLOR_CHIP_CLASS = 'gfm-color_chip'

      CSS   = 'code'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      def call
        doc.xpath(XPATH).each do |node|
          color = ColorParser.parse(node.content)
          node << color_chip(color) if color
        end

        doc
      end

      private

      def color_chip(color)
        checkerboard = doc.document.create_element('span', class: COLOR_CHIP_CLASS)
        chip = doc.document.create_element('span', style: inline_styles(color: color))

        checkerboard << chip
      end

      def inline_styles(color:)
        "background-color: #{color};"
      end
    end
  end
end
