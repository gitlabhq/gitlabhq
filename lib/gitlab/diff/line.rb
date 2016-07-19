module Gitlab
  module Diff
    class Line
      attr_reader :type, :index, :old_pos, :new_pos
      attr_accessor :text

      def initialize(text, type, index, old_pos, new_pos)
        @text, @type, @index = text, type, index
        @old_pos, @new_pos = old_pos, new_pos
      end

      def old_line
        old_pos unless added? || meta?
      end

      def new_line
        new_pos unless removed? || meta?
      end

      def unchanged?
        type.nil?
      end

      def added?
        type == 'new'
      end

      def removed?
        type == 'old'
      end

      def meta?
        type == 'match' || type == 'nonewline'
      end
    end
  end
end
