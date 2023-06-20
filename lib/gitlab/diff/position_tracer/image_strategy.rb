# frozen_string_literal: true

module Gitlab
  module Diff
    class PositionTracer
      class ImageStrategy < FileStrategy
        private

        def new_position(position, diff_file)
          Position.new(
            diff_file: diff_file,
            x: position.x,
            y: position.y,
            width: position.width,
            height: position.height,
            position_type: position.position_type
          )
        end
      end
    end
  end
end
