# frozen_string_literal: true

module Banzai
  module Filter
    # Looks for attributes that are specified for an element.  Follows the basic syntax laid out
    # in https://github.com/jgm/commonmark-hs/blob/master/commonmark-extensions/test/attributes.md
    # For example,
    #   ![](http://example.com/image.jpg){width=50%}
    #
    # However we currently have the following limitations:
    # - only support images
    # - only support the `width` and `height` attributes
    # - attributes can not span multiple lines
    # - unsupported attributes are thrown away
    class AttributesFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck

      CSS   = 'img'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      ATTRIBUTES_PATTERN = %r{\A(?<matched>\{(?<attributes>.{1,100})\})}
      WIDTH_HEIGHT_REGEX = %r{\A(?<name>height|width)="?(?<size>[\w%]{1,10})"?\z}
      VALID_SIZE_REGEX   = %r{\A\d{1,4}(%|px)?\z}

      def call
        doc.xpath(XPATH).each do |img|
          sibling = img.next
          next unless sibling && sibling.text? && sibling.content.first == '{'

          match = sibling.content.match(ATTRIBUTES_PATTERN)
          next unless match && match[:attributes]

          match[:attributes].split(' ').each do |attribute|
            next unless attribute.match?(WIDTH_HEIGHT_REGEX)

            attribute_match = attribute.match(WIDTH_HEIGHT_REGEX)
            img[attribute_match[:name].to_sym] = attribute_match[:size] if valid_size?(attribute_match[:size])
          end

          sibling.content = sibling.content.sub(match[:matched], '')
        end

        doc
      end

      private

      def valid_size?(size)
        size.match?(VALID_SIZE_REGEX)
      end
    end
  end
end
