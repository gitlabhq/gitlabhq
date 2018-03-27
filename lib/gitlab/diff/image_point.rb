module Gitlab
  module Diff
    class ImagePoint
      attr_reader :width, :height, :x, :y

      def initialize(width, height, x, y)
        @width = width
        @height = height
        @x = x
        @y = y
      end

      def to_h
        {
          width: width,
          height: height,
          x: x,
          y: y
        }
      end
    end
  end
end
