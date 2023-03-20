# frozen_string_literal: true

module Gitlab::Ci
  module Badge
    module Release
      # Template object will be passed to badge.svg.erb template.
      class Template < Badge::Template
        STATUS_COLOR = {
          latest: '#3076af',
          none: '#e05d44'
        }.freeze
        KEY_WIDTH_DEFAULT = 90
        VALUE_WIDTH_DEFAULT = 54
        VALUE_WIDTH_MAXIMUM = 200

        def initialize(badge)
          @tag = badge.tag || "none"
          @value_width = badge.customization[:value_width]
          super
        end

        def key_text
          @key_text || @entity.to_s
        end

        def key_width
          @key_width || KEY_WIDTH_DEFAULT
        end

        def value_text
          @tag.to_s
        end

        def value_width
          if @value_width && @value_width.between?(1, VALUE_WIDTH_MAXIMUM)
            @value_width
          else
            VALUE_WIDTH_DEFAULT
          end
        end

        def value_color
          STATUS_COLOR[@tag.to_sym] || STATUS_COLOR[:latest]
        end
      end
    end
  end
end
