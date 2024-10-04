# frozen_string_literal: true

module Gitlab::Ci
  module Badge
    ##
    # Abstract template class for badges
    #
    class Template
      MAX_KEY_TEXT_SIZE = 64
      MAX_KEY_WIDTH = 512
      DEFAULT_KEY_WIDTH = 62

      def initialize(badge)
        @entity = badge.entity
        @key_text = badge.customization[:key_text]
        @key_width = badge.customization[:key_width]
      end

      def key_text
        if @key_text && @key_text.size <= MAX_KEY_TEXT_SIZE
          @key_text
        else
          @entity.to_s
        end
      end

      def value_text
        raise NotImplementedError
      end

      def key_width
        if @key_width && @key_width.between?(1, MAX_KEY_WIDTH)
          @key_width
        else
          DEFAULT_KEY_WIDTH
        end
      end

      def value_width
        raise NotImplementedError
      end

      def value_color
        raise NotImplementedError
      end

      def key_color
        '#555'
      end

      def key_text_anchor
        key_width / 2
      end

      def value_text_anchor
        key_width + (value_width / 2)
      end

      def width
        key_width + value_width
      end
    end
  end
end
