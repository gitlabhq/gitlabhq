module Gitlab
  module Diff
    module Formatters
      class ImageFormatter < BaseFormatter
        attr_reader :width
        attr_reader :height
        attr_reader :x
        attr_reader :y

        def initialize(attrs)
          @x = attrs[:x]
          @y = attrs[:y]
          @width = attrs[:width]
          @height = attrs[:height]

          super(attrs)
        end

        def key
          @key ||= super.push(x, y)
        end

        def complete?
          x && y && width && height
        end

        def to_h
          super.merge(width: width, height: height, x: x, y: y)
        end

        def position_type
          "image"
        end

        def ==(other)
          other.is_a?(self.class) &&
            x == other.x &&
            y == other.y
        end
      end
    end
  end
end
