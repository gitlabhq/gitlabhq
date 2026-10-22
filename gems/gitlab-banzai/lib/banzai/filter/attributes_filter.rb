# frozen_string_literal: true

module Banzai
  module Filter
    # Looks for attributes that are specified for an element.  Follows the basic syntax laid out
    # in https://github.com/jgm/commonmark-hs/blob/master/commonmark-extensions/test/attributes.md
    # For example,
    #   ![](http://example.com/image.jpg){width=50% .float-right}
    #
    # However we currently have the following limitations:
    # - only support images
    # - only support the `width` and `height` attributes
    # - only support the `.float-right`, `.float-left`, and `.float-none` classes
    # - attributes can not span multiple lines
    # - unsupported attributes are thrown away
    class AttributesFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck

      CSS   = 'img'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      # Matches the attributes string between the curly braces i.e. { width=50% .float-right }
      ATTRIBUTES_PATTERN = %r{\A(?<matched>\{(?<attributes>.{1,100})\})}

      # Validator regex to check if the value is a valid size
      VALID_SIZE_REGEX   = %r{\A\d{1,4}(%|px)?\z}

      # Allowed values and their corresponding value validator regex
      VALUE_REGEX = %r{\A(?<name>[\w-]+)="?(?<value>[^"\s]+)"?\z}
      ALLOWED_VALUES = {
        height: { value_regex: VALID_SIZE_REGEX },
        width: { value_regex: VALID_SIZE_REGEX }
      }.freeze

      # Allowed classes and their corresponding class selector
      CLASS_REGEX = %r{\A\.(?<class_name>[\w-]+)\z}
      ALLOWED_CLASSES = {
        'float-right' => { class: 'glfm-float-right' },
        'float-left' => { class: 'glfm-float-left' },
        'float-none' => { class: 'glfm-float-none' }
      }.freeze

      def call
        doc.xpath(XPATH).each do |img|
          sibling = img.next
          next unless sibling && sibling.text? && sibling.content.first == '{'

          match = sibling.content.match(ATTRIBUTES_PATTERN)
          next unless match && match[:attributes]

          match[:attributes].split(' ').each { |attribute| process_attribute(img, attribute) }

          sibling.content = sibling.content.sub(match[:matched], '')
        end

        doc
      end

      private

      def process_attribute(node, attribute)
        case attribute
        when VALUE_REGEX then handle_value_attribute(node, $~)
        when CLASS_REGEX then handle_class_attribute(node, $~)
        end
      end

      def handle_value_attribute(node, match)
        name = match[:name].to_sym
        value = match[:value]
        node[name] = value if ALLOWED_VALUES[name]&.dig(:value_regex)&.match?(value)
      end

      def handle_class_attribute(node, match)
        class_name = match[:class_name]

        return if (mapped_class_name = ALLOWED_CLASSES[class_name]&.dig(:class)).blank?

        node[:class] = [node[:class], mapped_class_name].compact.join(' ')
      end
    end
  end
end
