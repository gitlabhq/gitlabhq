# frozen_string_literal: true

# Responsible for keeping track of line numbers and created Gitlab::Diff::Line objects
module Gitlab
  module WordDiff
    class PositionsCounter
      def initialize
        @pos_old = 1
        @pos_new = 1
        @line_obj_index = 0
      end

      attr_reader :pos_old, :pos_new, :line_obj_index

      def increase_pos_num
        @pos_old += 1
        @pos_new += 1
      end

      def increase_obj_index
        @line_obj_index += 1
      end

      def set_pos_num(old:, new:)
        @pos_old = old
        @pos_new = new
      end
    end
  end
end
