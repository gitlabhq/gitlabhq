module Gitlab
  module Diff
    class ImagePoint
      attr_reader :width, :height, :x_axis, :y_axis

      def initialize(width, height, x_axis, y_axis)
        @width = width
        @height = height
        @x_axis = x_axis
        @y_axis = y_axis
      end

      # Create superclass method with NotImplemented
      def key_attributes
        [x_axis, y_axis]
      end

      def as_json(opts = nil)
        {
          width: width,
          height: height,
          x_axis: x_axis,
          y_axis: y_axis
        }
      end
      # Move to parent class
      def meta?
        false
      end
    end
  end
end
