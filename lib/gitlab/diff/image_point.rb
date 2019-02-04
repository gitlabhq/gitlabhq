# frozen_string_literal: true

module Gitlab
  module Diff
    class ImagePoint
      attr_reader :width, :height, :x, :y

      def initialize(width, height, new_x, new_y)
        @width = width
        @height = height
        @x = new_x
        @y = new_y
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
