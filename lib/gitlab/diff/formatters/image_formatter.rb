module Gitlab
  module Diff
    module Formatters
      class ImageFormatter < BaseFormatter
        attr_reader :width
        attr_reader :height
        attr_reader :x_axis
        attr_reader :y_axis

        def initialize(attrs)
          @x_axis = attrs[:x_axis]
          @y_axis = attrs[:y_axis]
          @width = attrs[:width]
          @height = attrs[:height]

          super(attrs)
        end

        def key
          @key ||= super.push(x_axis, y_axis)
        end

        def complete?
          x_axis && y_axis && width && height
        end

        def to_h
          super.merge(width: width, height: height, x_axis: x_axis, y_axis: y_axis)
        end

        def position_type
          "image"
        end

        def ==(other)
          other.is_a?(self.class) &&
            x_axis == other.x_axis &&
            y_axis == other.y_axis
        end
      end
    end
  end
end
