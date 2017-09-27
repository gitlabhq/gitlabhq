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

      def to_h
        {
          width: width,
          height: height,
          x_axis: x_axis,
          y_axis: y_axis
        }
      end
    end
  end
end
