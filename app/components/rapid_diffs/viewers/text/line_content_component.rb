# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class LineContentComponent < ViewComponent::Base
        def initialize(line:, position:)
          @line = line
          @position = position
        end

        def change_type
          return unless @line

          return 'added' if @line.added?

          'removed' if @line.removed?
        end
      end
    end
  end
end
