module Gitlab
  module Diff
    class Line
      attr_reader :type, :text, :index, :old_pos, :new_pos

      def initialize(text, type, index, old_pos, new_pos)
        @text, @type, @index = text, type, index
        @old_pos, @new_pos = old_pos, new_pos
      end

      def added?
        type == 'new'
      end

      def removed?
        type == 'old'
      end
    end
  end
end
