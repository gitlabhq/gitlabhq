# frozen_string_literal: true

module Gitlab
  module TemplateParser
    # A class for tracking state when evaluating a template
    class EvalState
      MAX_LOOPS = 4

      def initialize
        @loops = 0
      end

      def enter_loop
        if @loops == MAX_LOOPS
          raise Error, "You can only nest up to #{MAX_LOOPS} loops"
        end

        @loops += 1
        retval = yield
        @loops -= 1

        retval
      end
    end
  end
end
