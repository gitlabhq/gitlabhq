# frozen_string_literal: true

module Gitlab
  module Ci
    module Badge
      module Custom
        ##
        # Class that represents a custom badge template.
        #
        # Template object will be passed to badge.svg.erb template.
        #
        class Template < Badge::Template
          VALUE_WIDTH_DEFAULT = 54
          VALUE_WIDTH_MAXIMUM = 200
          KEY_COLOR_DEFAULT = '#9f9f9f'
          VALUE_COLOR_DEFAULT = '#e05d44'
          VALUE_TEXT_DEFAULT = 'none'
          MAX_VALUE_TEXT_SIZE = 128

          HEX_COLOR_3_REGEX = /\A([a-f0-9])\1{2}\z/ # 3-char hex color must be repeated letters, e.g. "fff"
          HEX_COLOR_6_REGEX = /\A[a-f0-9]{6}\z/
          NAMED_COLOR_REGEX = /\A[a-z]{3,}\z/ # 3 chars minimum, e.g. "red"
          MAX_COLOR_LENGTH = 22 # e.g. "lightgoldenrodyellow"

          def initialize(badge)
            @badge = badge
            @key_color = badge.customization[:key_color]
            @value_width = badge.customization[:value_width]
            @value_color = badge.customization[:value_color]
            @value_text = badge.customization[:value_text]

            super
          end

          def value_width
            return @value_width if @value_width && @value_width.between?(1, VALUE_WIDTH_MAXIMUM)

            VALUE_WIDTH_DEFAULT
          end

          def key_color
            parse_color(@key_color, KEY_COLOR_DEFAULT)
          end

          def value_text
            return @value_text if @value_text && @value_text.size <= MAX_VALUE_TEXT_SIZE

            VALUE_TEXT_DEFAULT
          end

          def value_color
            parse_color(@value_color, VALUE_COLOR_DEFAULT)
          end

          private

          def parse_color(input_color, default_color)
            color = input_color.to_s.downcase.strip.delete_prefix('#')

            if color.present? && color.size <= MAX_COLOR_LENGTH
              return "##{color}" if Regexp.union(HEX_COLOR_3_REGEX, HEX_COLOR_6_REGEX).match?(color)
              return color if NAMED_COLOR_REGEX.match?(color)
            end

            default_color
          end
        end
      end
    end
  end
end
